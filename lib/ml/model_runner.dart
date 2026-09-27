// The one seam between the classifier and the TFLite runtime.
//
// `tflite_flutter` is built on `dart:ffi`, which a browser cannot compile.
// Importing it through this file means phones get the real interpreter and a
// browser preview gets a stub that reports "no model" — so the rest of the
// app can be clicked through in Chrome while the Android build is unchanged.
export 'model_runner_native.dart'
    if (dart.library.js_interop) 'model_runner_web.dart';
