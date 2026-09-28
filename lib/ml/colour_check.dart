import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Colour families a farmer would name when describing a dropping.
enum ColourFamily { green, brown, white, red, yellow }

/// How much of the middle of the photo falls in each colour family.
///
/// This is a measurement of the photo, made by the app — not a reading of the
/// model. The model scores the image as a whole and does not report colour,
/// texture or anything else separately, so the AI Analysis tab shows this
/// next to the model's scores as "what the photo shows", never as "why the
/// model decided".
class ColourProfile {
  /// Share of the measured pixels, 0–1, for each family. Pixels that fit no
  /// family (grey litter, shadows) are left out, so these need not sum to 1.
  final Map<ColourFamily, double> shares;

  const ColourProfile(this.shares);

  ColourFamily? get dominant {
    ColourFamily? best;
    double top = 0.08; // below this, nothing really stands out
    shares.forEach((ColourFamily k, double v) {
      if (v > top) {
        top = v;
        best = k;
      }
    });
    return best;
  }
}

/// Measures the central 60% of the photo — where the capture rules tell the
/// farmer to put the dropping. Pure Dart, so it runs in a background isolate.
ColourProfile? measureColours(Uint8List bytes) {
  final img.Image? decoded = img.decodeImage(bytes);
  if (decoded == null) return null;
  // Small is plenty for colour shares, and keeps this well under a second.
  final img.Image small = img.copyResize(decoded, width: 120);
  final int x0 = (small.width * 0.2).round();
  final int x1 = (small.width * 0.8).round();
  final int y0 = (small.height * 0.2).round();
  final int y1 = (small.height * 0.8).round();

  final Map<ColourFamily, int> counts = <ColourFamily, int>{
    for (final ColourFamily f in ColourFamily.values) f: 0,
  };
  int total = 0;
  final List<num> hsv = <num>[0, 0, 0];

  for (int y = y0; y < y1; y++) {
    for (int x = x0; x < x1; x++) {
      final img.Pixel p = small.getPixel(x, y);
      img.rgbToHsv(p.r / 255, p.g / 255, p.b / 255, hsv);
      total++;
      final double h = hsv[0].toDouble();
      final double s = hsv[1].toDouble();
      final double v = hsv[2].toDouble();

      ColourFamily? f;
      if (s < 0.18) {
        if (v > 0.72) f = ColourFamily.white; // urate cap, pale or chalky
      } else if (v < 0.22) {
        f = ColourFamily.brown; // very dark reads as dark brown
      } else if (h < 15 || h >= 340) {
        if (s > 0.35) f = ColourFamily.red;
      } else if (h < 42) {
        f = ColourFamily.brown;
      } else if (h < 68) {
        f = ColourFamily.yellow;
      } else if (h < 170) {
        f = ColourFamily.green;
      }
      if (f != null) counts[f] = counts[f]! + 1;
    }
  }
  if (total == 0) return null;
  return ColourProfile(<ColourFamily, double>{
    for (final ColourFamily f in ColourFamily.values) f: counts[f]! / total,
  });
}
