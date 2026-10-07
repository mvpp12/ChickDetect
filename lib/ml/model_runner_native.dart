import 'package:tflite_flutter/tflite_flutter.dart';

/// Runs the bundled model with TFLite. Used on Android and iOS.
class ModelRunner {
  final Interpreter _interpreter;

  ModelRunner._(this._interpreter);

  static Future<ModelRunner> fromAsset(String asset) async =>
      ModelRunner._(await Interpreter.fromAsset(asset));

  /// Name of the model's input tensor — how the classifier tells which
  /// pixel scaling the model expects.
  String get inputName => _interpreter.getInputTensor(0).name;

  void run(Object input, Object output) => _interpreter.run(input, output);

  void close() => _interpreter.close();
}
