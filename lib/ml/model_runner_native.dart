import 'package:tflite_flutter/tflite_flutter.dart';

/// Runs the bundled model with TFLite. Used on Android and iOS.
class ModelRunner {
  final Interpreter _interpreter;

  ModelRunner._(this._interpreter);

  static Future<ModelRunner> fromAsset(String asset) async =>
      ModelRunner._(await Interpreter.fromAsset(asset));

  void run(Object input, Object output) => _interpreter.run(input, output);

  void close() => _interpreter.close();
}
