import 'package:flutter/material.dart';

/// Colour, type and spacing for the whole app.
///
/// Every foreground here clears WCAG AA (4.5:1) against the surface it is
/// paired with at small text sizes. That is not decoration: this app is used
/// outdoors, on cheap screens, by people who may be reading it at arm's length
/// in a coop. Two colours are marked "shape only" and must never carry text.
class AppColor {
  AppColor._();

  // Brand green. Also means "healthy", because in this app they are the same
  // claim and splitting them into two greens only made the screen noisier.
  static const Color green900 = Color(0xFF0A4A33); // 10.3:1 on white
  static const Color green700 = Color(0xFF12714D); // 6.0:1 on white
  static const Color green500 = Color(0xFF178C5F);
  static const Color mint = Color(0xFFCDF0DC); // fill behind green900 text
  static const Color mintSoft = Color(0xFFE6F8EE);
  static const Color mintLine = Color(0xFFA8DFC2);

  // Severity. Separate from the brand on purpose — a finding's colour has to
  // mean something regardless of what the app's accent happens to be.
  static const Color danger = Color(0xFFB3261E);
  static const Color dangerSoft = Color(0xFFFDECEA);
  static const Color caution = Color(0xFFA85200);
  static const Color cautionSoft = Color(0xFFFEF3E2);

  // "This is how the app works" — offline notes, privacy, model facts.
  // Neither brand nor warning, because a normal state should not be coloured
  // like a problem.
  static const Color info = Color(0xFF3B4185);
  static const Color infoSoft = Color(0xFFEFF1FC);
  static const Color infoLine = Color(0xFFDCE0F6);

  // Reference material — the disease guide, the capture frame.
  static const Color reference = Color(0xFFB35E08); // white text clears AA
  static const Color referenceSoft = Color(0xFFFDF0E1);
  static const Color referenceText = Color(0xFF964D05);

  /// Shape only. 2.8:1 on white — never put text on or in this.
  static const Color referenceAccent = Color(0xFFE8801C);

  // Neutrals, biased slightly green so they read as chosen rather than default
  static const Color bg = Color(0xFFF6F8FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color fill = Color(0xFFEFF1F4);
  static const Color line = Color(0xFFE2E8E5);

  static const Color ink = Color(0xFF0E1B14); // 16.6:1 on bg
  static const Color ink2 = Color(0xFF38463E); // 9.3:1 on bg
  // 5.4:1 on bg, 5.0:1 on fill, 4.6:1 on line. The previous #64736B was
  // 4.4:1 on fill — under the floor wherever it sat on a segmented control.
  static const Color ink3 = Color(0xFF5B6A62);
  static const Color onDark = Color(0xFFFFFFFF);

  /// Numbered steps and every other piece of plain instruction. Neutral on
  /// purpose: red, amber and green are kept for the result itself and for real
  /// warnings, so a step never looks like a verdict. White on this is 9.3:1.
  static const Color steps = ink2;

  static const Color cameraBody = Color(0xFF0A130E);

  static const LinearGradient brand = LinearGradient(
    colors: <Color>[Color(0xFF0D5A3D), green500],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient hero = LinearGradient(
    colors: <Color>[green900, green700],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class Insets {
  Insets._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  static const double screen = 20;
  static const double card = 16;
  static const double section = 28;

  static const double rSm = 10;
  static const double rMd = 14;
  static const double rLg = 20;
  static const double rXl = 26;
  static const double rFull = 999;

  /// Android's minimum comfortable target. Every tappable row honours it.
  static const double tap = 48;
  static const double button = 54;
  static const double navBar = 72;
}

/// One scale, used everywhere. Poppins ships with the app so nothing falls
/// back to the platform font.
///
/// Only four weights ship — 300, 400, 500 and 700 — so the scale uses only
/// those. A `w600` here would silently render as 700, which is what the
/// previous scale did for every heading and every button label.
///
///   700  headings and figures — the thing to read first
///   500  labels, buttons, chips — things to act on
///   400  body
class AppFont {
  AppFont._();

  static const String family = 'Poppins';

  static const TextStyle display = TextStyle(
    fontFamily: family,
    fontSize: 27,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
    height: 1.2,
  );
  static const TextStyle h1 = TextStyle(
    fontFamily: family,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    height: 1.25,
  );
  static const TextStyle h2 = TextStyle(
    fontFamily: family,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.3,
  );
  static const TextStyle h3 = TextStyle(
    fontFamily: family,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.1,
    height: 1.35,
  );
  static const TextStyle body = TextStyle(
    fontFamily: family,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.55,
  );
  static const TextStyle bodySm = TextStyle(
    fontFamily: family,
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  static const TextStyle label = TextStyle(
    fontFamily: family,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );
  static const TextStyle labelSm = TextStyle(
    fontFamily: family,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
    height: 1.3,
  );
  static const TextStyle micro = TextStyle(
    fontFamily: family,
    fontSize: 9.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.7,
    height: 1.3,
  );

  /// For figures that line up in a column.
  static const TextStyle figure = TextStyle(
    fontFamily: family,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.8,
    height: 1.1,
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
  );
}
