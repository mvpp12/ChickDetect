import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;

import 'model_runner.dart';

/// Raw output of one inference: every class with its score.
class Prediction {
  /// Label as it appears in `labels.txt`, lower-cased.
  final String label;
  final double confidence;

  /// All classes, label to score, summing to about 1.
  final Map<String, double> scores;

  const Prediction({
    required this.label,
    required this.confidence,
    required this.scores,
  });

  /// Gap between the best and second-best score. A win by 0.02 means the model
  /// is guessing between two classes, however high the top figure looks.
  double get margin {
    final List<double> sorted = scores.values.toList()
      ..sort((double a, double b) => b.compareTo(a));
    if (sorted.length < 2) return 1;
    return sorted[0] - sorted[1];
  }
}

/// The on-device classifier.
///
/// Same model file and same preprocessing as the previous version — this is
/// the part of the app that is deliberately unchanged, because it is the part
/// that was trained and validated. What changed is everything around it: the
/// photo is checked before it gets here, and the answer is gated after.
class Classifier {
  ModelRunner? _interpreter;
  List<String> _labels = const <String>[];
  bool _ready = false;

  bool get isReady => _ready;
  List<String> get labels => _labels;

  /// Input edge the graph expects. MobileNetV2 at 224×224.
  static const int inputSize = 224;

  /// How pixels are scaled before they enter the graph.
  ///
  /// This model has no normalisation baked in — its first op is a convolution
  /// on the raw tensor — so the app has to match whatever the training script
  /// did. `/255` puts pixels in 0..1, which is what the previous version used.
  /// If the notebook used `mobilenet_v2.preprocess_input`, the correct range
  /// is -1..1 and this is the one line that has to change.
  static double _normalise(num channel) => channel / 255.0;

  Future<void> load() async {
    if (_ready) return;
    final String raw = await rootBundle.loadString('assets/models/labels.txt');
    _labels = raw
        .split('\n')
        .map((String l) => l.trim().toLowerCase())
        .where((String l) => l.isNotEmpty)
        .toList(growable: false);

    _interpreter = await ModelRunner.fromAsset('assets/models/model.tflite');
    _ready = true;

    if (kDebugMode) {
      debugPrint('Classifier ready: ${_labels.length} classes $_labels');
    }
  }

  /// Runs the model on already-decoded image bytes.
  ///
  /// Throws [StateError] if called before [load] finishes — the UI never
  /// enables the shutter until then.
  Prediction run(Uint8List bytes) => _runResized(_prepare(bytes));

  /// Decodes and resizes to the graph's input — the one preparation both
  /// [run] and [explain] use, so the explanation is of the same input.
  img.Image _prepare(Uint8List bytes) {
    final img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw const FormatException('Could not decode the captured image');
    }
    return img.copyResize(decoded, width: inputSize, height: inputSize);
  }

  Prediction _runResized(img.Image resized) {
    final ModelRunner? interpreter = _interpreter;
    if (!_ready || interpreter == null) {
      throw StateError('Classifier used before load() completed');
    }

    final List<List<List<List<double>>>> input = <List<List<List<double>>>>[
      List<List<List<double>>>.generate(inputSize, (int y) {
        return List<List<double>>.generate(inputSize, (int x) {
          final img.Pixel p = resized.getPixel(x, y);
          return <double>[_normalise(p.r), _normalise(p.g), _normalise(p.b)];
        });
      }),
    ];

    final List<List<double>> output = <List<double>>[
      List<double>.filled(_labels.length, 0),
    ];

    interpreter.run(input, output);

    final List<double> row = output[0];
    final Map<String, double> scores = <String, double>{};
    int best = 0;
    for (int i = 0; i < _labels.length; i++) {
      scores[_labels[i]] = row[i];
      if (row[i] > row[best]) best = i;
    }

    return Prediction(
      label: _labels[best],
      confidence: row[best],
      scores: scores,
    );
  }

  /// Which parts of the photo the answer depended on — occlusion sensitivity.
  ///
  /// The photo is split into a [grid]×[grid] grid. Each square in turn is
  /// covered with plain grey and the model is run again; the more the score
  /// for [label] falls, the more that square mattered. This is a genuine
  /// measurement of this model on this photo, not an illustration — which is
  /// why the app uses it instead of inventing per-feature percentages the
  /// model does not produce.
  ///
  /// Returns grid² values in 0–1, row by row (1 = mattered most), or null if
  /// the model is not loaded. Runs grid² + 1 inferences, yielding between them
  /// so the screen keeps drawing its progress.
  Future<List<double>?> explain(
    Uint8List bytes,
    String label, {
    int grid = 4,
    void Function(double progress)? onProgress,
  }) async {
    if (!_ready) return null;
    final img.Image base = _prepare(bytes);
    final double before = _runResized(base).scores[label] ?? 0;
    final int cell = (inputSize / grid).ceil();
    final img.Color grey = img.ColorRgb8(128, 128, 128);
    final List<double> drops = <double>[];

    for (int gy = 0; gy < grid; gy++) {
      for (int gx = 0; gx < grid; gx++) {
        final img.Image covered = base.clone();
        img.fillRect(
          covered,
          x1: gx * cell,
          y1: gy * cell,
          x2: ((gx + 1) * cell - 1).clamp(0, inputSize - 1),
          y2: ((gy + 1) * cell - 1).clamp(0, inputSize - 1),
          color: grey,
        );
        final double after = _runResized(covered).scores[label] ?? 0;
        drops.add((before - after).clamp(0.0, 1.0));
        onProgress?.call(drops.length / (grid * grid));
        await Future<void>.delayed(Duration.zero);
      }
    }

    final double top = drops.reduce((double a, double b) => a > b ? a : b);
    // Nothing moved the score: no square mattered more than another.
    if (top < 0.01) return List<double>.filled(drops.length, 0);
    return drops.map((double d) => d / top).toList(growable: false);
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _ready = false;
  }
}
