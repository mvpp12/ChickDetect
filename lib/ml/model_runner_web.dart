/// Browser stand-in. TFLite cannot run here, so loading always fails, and the
/// app shows its ordinary "model did not load" state with scanning disabled.
class ModelRunner {
  ModelRunner._();

  static Future<ModelRunner> fromAsset(String asset) async =>
      throw UnsupportedError('The on-device model does not run in a browser.');

  void run(Object input, Object output) =>
      throw UnsupportedError('The on-device model does not run in a browser.');

  void close() {}
}
