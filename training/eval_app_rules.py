"""What the app would actually show for each held-out test photo.

The training report scores the model's top answer. The app adds rules on top
(ChickDetect's Decision class): a disease needs 65 % certainty, Healthy needs
85 %, the top answer must lead the next by 15 points, and a "not a dropping"
top answer is reported as such. This replays those rules on the same test
split train_model.py uses, so we see what a farmer would see per class.
"""
import os
import sys
from collections import Counter, defaultdict
from pathlib import Path

os.environ.setdefault('TF_CPP_MIN_LOG_LEVEL', '2')
sys.path.insert(0, str(Path(__file__).resolve().parent))

import numpy as np  # noqa: E402
import tensorflow as tf  # noqa: E402

import train_model as tm  # noqa: E402

CONDITION_BAR = 0.65
HEALTHY_BAR = 0.85
MARGIN_BAR = 0.15


def verdict(probs):
    order = np.argsort(probs)[::-1]
    top, second = order[0], order[1]
    label = tm.LABELS[top]
    if label == 'not_dropping':
        return 'not a dropping'
    bar = HEALTHY_BAR if label == 'healthy' else CONDITION_BAR
    if probs[top] < bar or probs[top] - probs[second] < MARGIN_BAR:
        return 'retake (Kunan ulit)'
    return label


def main():
    droppings = Path(sys.argv[1])
    not_dropping = Path(sys.argv[2])
    model = Path(sys.argv[3])
    paths, y = tm.gather(droppings, not_dropping, 300)
    _, _, te = tm.grouped_split(paths, y, y != tm.LABELS.index('not_dropping'))
    it = tf.lite.Interpreter(model_path=str(model))
    it.allocate_tensors()
    i_in = it.get_input_details()[0]['index']
    i_out = it.get_output_details()[0]['index']
    table = defaultdict(Counter)
    ncd_probs = []
    for p, t in zip(paths[te], y[te]):
        it.set_tensor(i_in, tm.load(p).numpy()[None])
        it.invoke()
        pr = it.get_tensor(i_out)[0]
        table[tm.LABELS[t]][verdict(pr)] += 1
        if tm.LABELS[t] == 'newcastle':
            ncd_probs.append(pr[tm.LABELS.index('newcastle')])
    for true in tm.LABELS:
        n = sum(table[true].values())
        print(f'\nTrue {true} ({n} photos) -> app shows:')
        for k, v in table[true].most_common():
            print(f'   {k:22s} {v:4d}  ({v / n * 100:5.1f}%)')
    q = np.percentile(ncd_probs, [10, 25, 50, 75, 90])
    print('\nNewcastle score on true Newcastle photos, percentiles 10/25/50/75/90:',
          ' '.join(f'{v:.2f}' for v in q))


if __name__ == '__main__':
    main()
