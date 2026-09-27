import 'package:flutter/widgets.dart';

/// Every icon in the app, named for what it means here rather than what it
/// depicts.
///
/// Phosphor (phosphoricons.com, MIT — see assets/fonts/PHOSPHOR_LICENSE.txt)
/// rather than the Material set: one stroke weight and one corner style across
/// all of them, and a filled twin for each outline, so a selected tab reads as
/// selected by shape and not only by colour.
///
/// The three font files are vendored in assets/fonts instead of pulled in as a
/// package. The phosphor_flutter package no longer compiles on current Flutter
/// (it subclasses IconData, which is now final) and has not been updated; a
/// font file and a table of code points cannot break that way. Release builds
/// subset the fonts down to the glyphs referenced here.
///
/// Screens reference these names, never a raw glyph. Swapping the set later is
/// then a change to this file alone.
class AppIcons {
  AppIcons._();

  static const String _regular = 'PhosphorRegular';
  static const String _fill = 'PhosphorFill';
  static const String _bold = 'PhosphorBold';

  // ── navigation ─────────────────────────────────────────────────────────
  static const IconData scan = IconData(0xe10e, fontFamily: _regular);
  static const IconData scanActive = IconData(0xe10e, fontFamily: _fill);
  static const IconData records = IconData(0xe198, fontFamily: _regular);
  static const IconData recordsActive = IconData(0xe198, fontFamily: _fill);
  static const IconData guide = IconData(0xe8f2, fontFamily: _regular);
  static const IconData guideActive = IconData(0xe8f2, fontFamily: _fill);
  static const IconData settings = IconData(0xe272, fontFamily: _regular);

  // ── camera ─────────────────────────────────────────────────────────────
  static const IconData flashOn = IconData(0xe2de, fontFamily: _fill);
  static const IconData flashOff = IconData(0xe2e0, fontFamily: _regular);
  static const IconData gallery = IconData(0xe836, fontFamily: _regular);
  static const IconData help = IconData(0xe3e8, fontFamily: _regular);
  static const IconData cameraOff = IconData(0xe110, fontFamily: _regular);
  static const IconData retake = IconData(0xe038, fontFamily: _regular);
  static const IconData model = IconData(0xe610, fontFamily: _regular);

  // ── photo faults ───────────────────────────────────────────────────────
  static const IconData blurred = IconData(0xe224, fontFamily: _regular);
  static const IconData tooDark = IconData(0xe330, fontFamily: _regular);
  static const IconData tooBright = IconData(0xe472, fontFamily: _regular);
  static const IconData noSubject = IconData(0xe626, fontFamily: _regular);

  // ── photo rules ────────────────────────────────────────────────────────
  static const IconData fresh = IconData(0xe19a, fontFamily: _regular);
  static const IconData centred = IconData(0xe1d6, fontFamily: _regular);
  static const IconData bright = IconData(0xe472, fontFamily: _regular);

  // ── verdicts ───────────────────────────────────────────────────────────
  static const IconData healthy = IconData(0xe606, fontFamily: _fill);
  static const IconData serious = IconData(0xe4e0, fontFamily: _fill);
  static const IconData unsure = IconData(0xe3e8, fontFamily: _fill);
  static const IconData rejected = IconData(0xe3de, fontFamily: _regular);

  // ── report sections ────────────────────────────────────────────────────
  static const IconData spread = IconData(0xe4ae, fontFamily: _regular);
  static const IconData people = IconData(0xe4d6, fontFamily: _regular);
  static const IconData law = IconData(0xea32, fontFamily: _regular);
  static const IconData firstDay = IconData(0xe2de, fontFamily: _regular);
  static const IconData thisWeek = IconData(0xe712, fontFamily: _regular);
  static const IconData about = IconData(0xe0e6, fontFamily: _regular);
  static const IconData lookFor = IconData(0xe220, fontFamily: _regular);
  static const IconData neverDo = IconData(0xe3de, fontFamily: _regular);
  static const IconData getHelp = IconData(0xe56e, fontFamily: _regular);
  static const IconData photoQuality = IconData(0xe00a, fontFamily: _regular);
  static const IconData scores = IconData(0xe150, fontFamily: _regular);
  static const IconData onDevice = IconData(0xe1e0, fontFamily: _regular);
  static const IconData conditions = IconData(0xe7d6, fontFamily: _regular);
  static const IconData info = IconData(0xe2ce, fontFamily: _regular);
  static const IconData fullReport = IconData(0xe0a8, fontFamily: _regular);

  // ── records ────────────────────────────────────────────────────────────
  static const IconData search = IconData(0xe30c, fontFamily: _regular);
  static const IconData noResults = IconData(0xe30e, fontFamily: _regular);
  static const IconData trendUp = IconData(0xe4ae, fontFamily: _bold);
  static const IconData trendDown = IconData(0xe4ac, fontFamily: _bold);
  static const IconData trendFlat = IconData(0xe06c, fontFamily: _bold);
  static const IconData noTrend = IconData(0xe32a, fontFamily: _bold);
  static const IconData coop = IconData(0xec72, fontFamily: _regular);
  static const IconData note = IconData(0xe34c, fontFamily: _regular);
  static const IconData saved = IconData(0xe184, fontFamily: _fill);
  static const IconData offline = IconData(0xe1b6, fontFamily: _regular);
  static const IconData emptyLog = IconData(0xebb6, fontFamily: _regular);

  // ── settings ───────────────────────────────────────────────────────────
  static const IconData language = IconData(0xe4a2, fontFamily: _regular);
  static const IconData privacy = IconData(0xe40c, fontFamily: _regular);
  static const IconData exportCsv = IconData(0xe476, fontFamily: _regular);
  static const IconData replay = IconData(0xe3d2, fontFamily: _regular);

  // ── generic ────────────────────────────────────────────────────────────
  static const IconData delete = IconData(0xe4a6, fontFamily: _regular);
  static const IconData edit = IconData(0xe3b4, fontFamily: _regular);
  static const IconData close = IconData(0xe4f6, fontFamily: _regular);
  static const IconData check = IconData(0xe182, fontFamily: _bold);
  static const IconData cross = IconData(0xe4f6, fontFamily: _bold);
  static const IconData chevron = IconData(0xe13a, fontFamily: _regular);
  static const IconData expand = IconData(0xe136, fontFamily: _regular);
  static const IconData collapse = IconData(0xe13c, fontFamily: _regular);
  static const IconData image = IconData(0xe2ca, fontFamily: _regular);
  static const IconData imageBroken = IconData(0xe7a8, fontFamily: _regular);
}
