"""Train the ChickDetect model: 4 dropping classes plus "not a dropping".

Why this script exists
----------------------
The model shipped before this was trained with four classes only. Shown
anything that was not a dropping — a floor, a hand, the app's own logo — it
still had to choose one of the four, and it chose Coccidiosis, often at
97–100 % certainty. No threshold in the app can tell that apart from a real
Coccidiosis reading. The fix is a fifth class the model can answer with.

It also settles how pixels are scaled. The old model's scaling lived only in a
notebook, and the app had to guess. Here the scaling is a layer *inside* the
model, so the app feeds plain 0–255 RGB and the two can never disagree.

Method (chosen for an 8 GB laptop with no GPU)
-----------------------------------------------
MobileNetV2 pretrained on ImageNet is used as a frozen feature extractor.
Every image is passed through it once (plus augmented copies of the training
images), and only a small classification head is trained on those features.
This is standard transfer learning; it trains in minutes on a CPU.

Split: stratified 70 / 15 / 15 train / validation / test, seed 42 — the same
proportions as the earlier study — but grouped so that duplicate and
flipped/rotated copies of a photo always land in the same split (see
copy_signature). A plain random split lets twins straddle train and test and
overstates accuracy; the first run of this script did exactly that.

Usage
-----
    python train_model.py --droppings D:/ChickDetect-Datasets/droppings \
        --not-dropping D:/ChickDetect-Datasets/not_dropping/natural_images \
        --out D:/ChickDetect-Datasets/output

Outputs: model.tflite, labels.txt, report.json, report.txt in --out.
"""
from __future__ import annotations

import argparse
import csv
import json
import os
import random
import time
from collections import Counter
from pathlib import Path

import numpy as np

# Keep Keras downloads (the ImageNet weights) off a nearly full C: drive.
os.environ.setdefault('KERAS_HOME', str(Path(__file__).resolve().parent / '.keras'))
os.environ.setdefault('TF_CPP_MIN_LOG_LEVEL', '2')

import tensorflow as tf  # noqa: E402
from PIL import Image  # noqa: E402
from sklearn.metrics import confusion_matrix  # noqa: E402
from sklearn.model_selection import StratifiedGroupKFold  # noqa: E402

SEED = 42
SIZE = 224
# Order is the model's output order and the order written to labels.txt.
LABELS = ['healthy', 'coccidiosis', 'salmonella', 'newcastle', 'not_dropping']
CSV_TO_LABEL = {
    'Healthy': 'healthy',
    'Coccidiosis': 'coccidiosis',
    'Salmonella': 'salmonella',
    'New Castle Disease': 'newcastle',
}


def gather(droppings: Path, not_dropping: Path, per_category: int):
    paths, labels = [], []
    with open(droppings / 'train_data.csv', encoding='utf-8') as f:
        for row in csv.DictReader(f):
            p = droppings / 'Train' / row['images']
            if p.exists():
                paths.append(str(p))
                labels.append(LABELS.index(CSV_TO_LABEL[row['label']]))
    rng = random.Random(SEED)
    for cat in sorted(d for d in not_dropping.iterdir() if d.is_dir()):
        files = sorted(str(p) for p in cat.iterdir()
                       if p.suffix.lower() in ('.jpg', '.jpeg', '.png'))
        rng.shuffle(files)
        for p in files[:per_category]:
            paths.append(p)
            labels.append(LABELS.index('not_dropping'))
    return np.array(paths), np.array(labels)


def copy_signature(path):
    """A tiny image fingerprint that ignores flips and 90° rotations.

    The Kaggle copy of the dataset holds 8,067 images where the original
    Zenodo release has 6,812: 280 files are exact duplicates and about 1,300
    are flipped or rotated copies of another image. Photos sharing a
    fingerprint are kept in the same split, so the test set never contains a
    twin of a training photo — otherwise the test score is inflated.
    """
    a = np.asarray(Image.open(path).convert('L').resize((8, 8), Image.BILINEAR),
                   dtype=np.int16)
    views = [a, a[:, ::-1], a[::-1], np.rot90(a), np.rot90(a, 2), np.rot90(a, 3),
             np.rot90(a)[:, ::-1], np.rot90(a)[::-1]]
    return min((v > v.mean()).astype(np.uint8).tobytes() for v in views).hex()


def grouped_split(paths, y, dropping_mask):
    """Stratified 70 / 15 / 15 split that keeps copies of a photo together."""
    groups = np.empty(len(paths), dtype=object)
    for i, p in enumerate(paths):
        groups[i] = copy_signature(p) if dropping_mask[i] else f'nd:{p}'
    _, gid = np.unique(groups, return_inverse=True)
    # 20 folds of ~5 % each: 3 folds test, 3 folds validation, 14 train.
    folds = np.empty(len(paths), dtype=int)
    for k, (_, idx) in enumerate(
            StratifiedGroupKFold(n_splits=20, shuffle=True, random_state=SEED)
            .split(paths, y, gid)):
        folds[idx] = k
    te = folds < 3
    va = (folds >= 3) & (folds < 6)
    tr = folds >= 6
    shared = (set(gid[te]) & set(gid[tr])) | (set(gid[va]) & set(gid[tr]))
    assert not shared, 'a photo group leaked across splits'
    n_groups = len(set(gid[dropping_mask]))
    print(f'dropping photos: {dropping_mask.sum()} in {n_groups} copy-groups',
          flush=True)
    return tr, va, te


def load(path):
    raw = tf.io.read_file(path)
    img = tf.image.decode_image(raw, channels=3, expand_animations=False)
    img = tf.image.resize(img, (SIZE, SIZE), method='area')
    return tf.cast(img, tf.float32)  # 0..255, exactly what the app feeds


AUGMENTS = {
    'orig': lambda x: x,
    'flip': lambda x: tf.image.flip_left_right(x),
    'rot90': lambda x: tf.image.rot90(x),
    'dark': lambda x: tf.clip_by_value(x * 0.75, 0.0, 255.0),
}


def build_extractor():
    inp = tf.keras.Input((SIZE, SIZE, 3), name='image_0_255')
    x = tf.keras.layers.Rescaling(1 / 127.5, offset=-1.0, name='to_minus1_1')(inp)
    base = tf.keras.applications.MobileNetV2(
        include_top=False, weights='imagenet', pooling='avg',
        input_shape=(SIZE, SIZE, 3))
    base.trainable = False
    return tf.keras.Model(inp, base(x, training=False), name='extractor')


def features(extractor, paths, augment='orig', batch=32):
    fn = AUGMENTS[augment]
    ds = (tf.data.Dataset.from_tensor_slices(paths)
          .map(lambda p: fn(load(p)), num_parallel_calls=2)
          .batch(batch).prefetch(1))
    return extractor.predict(ds, verbose=0)


def build_head(n_features):
    reg = tf.keras.regularizers.l2(1e-4)
    return tf.keras.Sequential([
        tf.keras.Input((n_features,)),
        tf.keras.layers.Dropout(0.3),
        tf.keras.layers.Dense(256, activation='relu', kernel_regularizer=reg),
        tf.keras.layers.Dropout(0.3),
        tf.keras.layers.Dense(len(LABELS), activation='softmax',
                              kernel_regularizer=reg),
    ], name='head')


def per_class(y_true, y_pred):
    out = {}
    for i, name in enumerate(LABELS):
        m = y_true == i
        out[name] = {
            'correct': int((y_pred[m] == i).sum()),
            'total': int(m.sum()),
            'accuracy': float((y_pred[m] == i).mean()) if m.any() else None,
        }
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--droppings', type=Path, required=True)
    ap.add_argument('--not-dropping', type=Path, required=True)
    ap.add_argument('--out', type=Path, required=True)
    ap.add_argument('--per-category', type=int, default=300,
                    help='not-dropping images taken from each category folder')
    ap.add_argument('--probe', type=Path, action='append', default=[],
                    help='extra folders of non-dropping images, test only')
    args = ap.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)
    tf.random.set_seed(SEED)
    np.random.seed(SEED)
    t0 = time.time()

    paths, y = gather(args.droppings, args.not_dropping, args.per_category)
    print('images per class:', {LABELS[k]: v for k, v in sorted(Counter(y).items())},
          flush=True)
    tr, va, te = grouped_split(paths, y, y != LABELS.index('not_dropping'))
    p_tr, y_tr = paths[tr], y[tr]
    p_va, y_va = paths[va], y[va]
    p_te, y_te = paths[te], y[te]
    print(f'split: train {len(p_tr)}  val {len(p_va)}  test {len(p_te)}', flush=True)

    extractor = build_extractor()
    feats_tr, labs_tr = [], []
    for aug in AUGMENTS:
        t = time.time()
        feats_tr.append(features(extractor, p_tr, aug))
        labs_tr.append(y_tr)
        print(f'features train/{aug}: {time.time() - t:.0f}s', flush=True)
    x_tr = np.concatenate(feats_tr)
    y_tr_aug = np.concatenate(labs_tr)
    x_va = features(extractor, p_va)
    x_te = features(extractor, p_te)
    print(f'features done in {time.time() - t0:.0f}s', flush=True)

    counts = Counter(y_tr_aug)
    weights = {k: len(y_tr_aug) / (len(LABELS) * v) for k, v in counts.items()}
    head = build_head(x_tr.shape[1])
    head.compile(optimizer=tf.keras.optimizers.Adam(1e-3),
                 loss='sparse_categorical_crossentropy', metrics=['accuracy'])
    head.fit(
        x_tr, y_tr_aug, validation_data=(x_va, y_va), epochs=200, batch_size=64,
        class_weight=weights, verbose=2,
        callbacks=[
            tf.keras.callbacks.EarlyStopping(monitor='val_loss', patience=12,
                                             restore_best_weights=True),
            tf.keras.callbacks.ReduceLROnPlateau(monitor='val_loss', factor=0.5,
                                                 patience=5),
        ])

    # ── one model: raw 0–255 image in, five probabilities out ──────────────
    inp = tf.keras.Input((SIZE, SIZE, 3), name='image_0_255')
    full = tf.keras.Model(inp, head(extractor(inp)), name='chickdetect')
    conv = tf.lite.TFLiteConverter.from_keras_model(full)
    tflite = conv.convert()
    (args.out / 'model.tflite').write_bytes(tflite)
    (args.out / 'labels.txt').write_text('\n'.join(LABELS) + '\n', encoding='utf-8')

    # ── evaluate the exported TFLite file, the thing the app actually runs ─
    it = tf.lite.Interpreter(model_content=tflite)
    it.allocate_tensors()
    i_in = it.get_input_details()[0]['index']
    i_out = it.get_output_details()[0]['index']

    def run_tflite(path_list):
        preds, probs = [], []
        for p in path_list:
            x = load(p).numpy()[None]
            it.set_tensor(i_in, x)
            it.invoke()
            pr = it.get_tensor(i_out)[0]
            preds.append(int(pr.argmax()))
            probs.append(pr)
        return np.array(preds), np.array(probs)

    pred_te, prob_te = run_tflite(p_te)
    acc = float((pred_te == y_te).mean())
    cm = confusion_matrix(y_te, pred_te, labels=list(range(len(LABELS))))
    # The four disease classes alone, comparable with the earlier study.
    m4 = y_te != LABELS.index('not_dropping')
    acc4 = float((pred_te[m4] == y_te[m4]).mean())
    sick_as_healthy = int(((y_te != 0) & (y_te != 4) & (pred_te == 0)).sum())

    probes = {}
    for folder in args.probe:
        files = sorted(str(p) for p in folder.rglob('*')
                       if p.suffix.lower() in ('.jpg', '.jpeg', '.png'))
        if files:
            pr, _ = run_tflite(files)
            probes[str(folder)] = {
                Path(f).name: LABELS[k] for f, k in zip(files, pr)}

    report = {
        'labels': LABELS,
        'input': 'float32 RGB 224x224, values 0..255 (scaling is inside the model)',
        'split': {'train': len(p_tr), 'val': len(p_va), 'test': len(p_te)},
        'test_accuracy_all_5': acc,
        'test_accuracy_4_dropping_classes': acc4,
        'sick_predicted_healthy': sick_as_healthy,
        'per_class': per_class(y_te, pred_te),
        'confusion_matrix_rows_true_cols_pred': cm.tolist(),
        'probes': probes,
        'seconds': round(time.time() - t0),
        'tflite_bytes': len(tflite),
    }
    (args.out / 'report.json').write_text(json.dumps(report, indent=2),
                                          encoding='utf-8')
    lines = [f'Test accuracy (5 classes): {acc * 100:.2f}%',
             f'Test accuracy (4 dropping classes): {acc4 * 100:.2f}%',
             f'Sick droppings predicted Healthy: {sick_as_healthy}', '']
    for name, r in report['per_class'].items():
        lines.append(f"{name:14s} {r['correct']:4d} / {r['total']:4d}  "
                     f"{(r['accuracy'] or 0) * 100:6.2f}%")
    lines += ['', 'Confusion matrix (rows = true, cols = predicted):',
              '               ' + ' '.join(f'{n[:6]:>7s}' for n in LABELS)]
    for n, row in zip(LABELS, cm):
        lines.append(f'{n:14s} ' + ' '.join(f'{v:7d}' for v in row))
    for folder, res in probes.items():
        lines += ['', f'Probe: {folder}'] + [f'  {k}: {v}' for k, v in res.items()]
    (args.out / 'report.txt').write_text('\n'.join(lines) + '\n', encoding='utf-8')
    print('\n'.join(lines), flush=True)


if __name__ == '__main__':
    main()
