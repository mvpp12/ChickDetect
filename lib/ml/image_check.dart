import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Why a photo was refused, or null when it passed.
enum PhotoFault { blurred, tooDark, tooBright, flat }

/// What the checker measured, kept with the scan so a result can be read back
/// later with the quality of its evidence attached.
class PhotoQuality {
  /// Variance of the Laplacian. Higher is sharper. Below ~55 is visibly soft
  /// at the size this app captures.
  final double sharpness;

  /// Mean luminance, 0–255.
  final double brightness;

  /// Standard deviation of luminance. A frame with almost no spread has no
  /// subject in it — a wall, a hand over the lens, an overexposed floor.
  final double spread;

  final PhotoFault? fault;

  const PhotoQuality({
    required this.sharpness,
    required this.brightness,
    required this.spread,
    required this.fault,
  });

  bool get usable => fault == null;

  /// 0–1, for the three meters on the detail screen. These are presentation
  /// scalings of the raw figures above, not separate measurements.
  double get sharpnessScore => (sharpness / 180).clamp(0.0, 1.0);
  double get brightnessScore {
    // Best around 125; falls off towards either end.
    final double d = (brightness - 125).abs();
    return (1 - d / 125).clamp(0.0, 1.0);
  }

  double get spreadScore => (spread / 60).clamp(0.0, 1.0);

  Map<String, dynamic> toJson() => <String, dynamic>{
    'sharpness': sharpness,
    'brightness': brightness,
    'spread': spread,
    'fault': fault?.name,
  };

  static PhotoQuality? fromJson(Object? raw) {
    if (raw is! Map) return null;
    double num0(Object? v) => v is num ? v.toDouble() : 0;
    PhotoFault? fault;
    final Object? f = raw['fault'];
    if (f is String) {
      for (final PhotoFault v in PhotoFault.values) {
        if (v.name == f) fault = v;
      }
    }
    return PhotoQuality(
      sharpness: num0(raw['sharpness']),
      brightness: num0(raw['brightness']),
      spread: num0(raw['spread']),
      fault: fault,
    );
  }
}

/// Checks a photo before the model ever sees it.
///
/// This is the single most important difference from the previous version.
/// The classifier has four classes and no "none of these" option, so a blurred
/// shot of a coop floor does not come back as an error — it comes back as a
/// confident disease, or worse, as a confident *healthy*. Refusing the photo
/// up front is the only honest way to say "I cannot read this", and it costs
/// the farmer ten seconds rather than a flock.
///
/// The thresholds are deliberately forgiving. A false refusal is an annoyance;
/// a false reading is the thing this exists to prevent, but refusing half of
/// all real photos would just teach people to ignore the warning.
class PhotoChecker {
  PhotoChecker._();

  static const double _minSharpness = 55;
  static const double _minBrightness = 42;
  static const double _maxBrightness = 232;
  static const double _minSpread = 16;

  /// Runs on a decoded image. Safe to call on a background isolate.
  static PhotoQuality inspect(img.Image source) {
    // Work small: the statistics are scale-sensitive, so every photo is
    // measured at the same width regardless of the camera that took it.
    final img.Image small = img.copyResize(source, width: 256);
    final int w = small.width;
    final int h = small.height;

    final Float32List lum = Float32List(w * h);
    double sum = 0;
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final img.Pixel p = small.getPixel(x, y);
        // Rec. 601 luma, which is what "brightness" means to an eye.
        final double v =
            0.299 * p.r.toDouble() +
            0.587 * p.g.toDouble() +
            0.114 * p.b.toDouble();
        lum[y * w + x] = v;
        sum += v;
      }
    }

    final int n = w * h;
    final double mean = sum / n;

    double varSum = 0;
    for (int i = 0; i < n; i++) {
      final double d = lum[i] - mean;
      varSum += d * d;
    }
    final double spread = math.sqrt(varSum / n);

    // Variance of the Laplacian — the standard cheap focus measure.
    double lapSum = 0;
    double lapSqSum = 0;
    int lapCount = 0;
    for (int y = 1; y < h - 1; y++) {
      for (int x = 1; x < w - 1; x++) {
        final int i = y * w + x;
        final double lap =
            4 * lum[i] - lum[i - 1] - lum[i + 1] - lum[i - w] - lum[i + w];
        lapSum += lap;
        lapSqSum += lap * lap;
        lapCount++;
      }
    }
    double sharpness = 0;
    if (lapCount > 0) {
      final double lapMean = lapSum / lapCount;
      sharpness = (lapSqSum / lapCount) - (lapMean * lapMean);
      if (sharpness < 0) sharpness = 0;
    }

    // Order matters. A frame that is both dark and flat is reported as dark,
    // because that is the fault the farmer can actually fix first.
    PhotoFault? fault;
    if (mean < _minBrightness) {
      fault = PhotoFault.tooDark;
    } else if (mean > _maxBrightness) {
      fault = PhotoFault.tooBright;
    } else if (spread < _minSpread) {
      fault = PhotoFault.flat;
    } else if (sharpness < _minSharpness) {
      fault = PhotoFault.blurred;
    }

    return PhotoQuality(
      sharpness: sharpness,
      brightness: mean,
      spread: spread,
      fault: fault,
    );
  }

  /// Decodes and inspects raw bytes. Returns null when the bytes are not an
  /// image the app can read at all.
  static PhotoQuality? inspectBytes(Uint8List bytes) {
    final img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) return null;
    return inspect(decoded);
  }
}
