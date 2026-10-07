# TensorFlow Lite: the runtime looks classes up by name, and the optional GPU
# delegate is referenced but not bundled. Without these the release shrinker
# either removes classes the model needs or fails on the missing GPU ones.
-keep class org.tensorflow.lite.** { *; }
-dontwarn org.tensorflow.lite.**
