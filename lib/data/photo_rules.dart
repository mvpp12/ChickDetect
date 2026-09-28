import 'package:flutter/material.dart';

import '../core/icons.dart';
import '../core/strings.dart';

/// One step of the first-run walkthrough.
///
/// These three carry the photographs shipped with the project, and the copy is
/// written to match what each photograph actually shows: aiming at a sample,
/// the model running on the phone, and the result. Writing capture rules over
/// a picture of an analysis screen — which is what the earlier version did —
/// leaves the reader trusting neither.
class FlowStep {
  final String asset;
  final String Function(L) title;
  final String Function(L) body;

  /// Only the capture step has a pass/fail pair; the other two are describing
  /// what the app does, where there is nothing for the farmer to get wrong.
  final String Function(L)? doLabel;
  final String Function(L)? dontLabel;

  const FlowStep({
    required this.asset,
    required this.title,
    required this.body,
    this.doLabel,
    this.dontLabel,
  });
}

/// The walkthrough shown after the landing card.
const List<FlowStep> kFlowSteps = <FlowStep>[
  FlowStep(
    asset: 'assets/onboarding/step_scan.png',
    title: _f1t,
    body: _f1b,
    doLabel: _f1d,
    dontLabel: _f1n,
  ),
  FlowStep(
    asset: 'assets/onboarding/step_analyze.png',
    title: _f2t,
    body: _f2b,
  ),
  FlowStep(asset: 'assets/onboarding/step_result.png', title: _f3t, body: _f3b),
];

/// One capture rule, for the Guide tab.
class PhotoRule {
  final IconData icon;
  final String Function(L) title;
  final String Function(L) body;
  final String Function(L) doLabel;
  final String Function(L) dontLabel;

  const PhotoRule({
    required this.icon,
    required this.title,
    required this.body,
    required this.doLabel,
    required this.dontLabel,
  });
}

/// The three rules that decide whether a photo is usable.
///
/// Defined once and read only by the Guide tab. The walkthrough above teaches
/// the app; these are the reference a farmer comes back to when a scan keeps
/// coming out unreadable.
const List<PhotoRule> kPhotoRules = <PhotoRule>[
  PhotoRule(
    icon: AppIcons.fresh,
    title: _r1t,
    body: _r1b,
    doLabel: _r1d,
    dontLabel: _r1n,
  ),
  PhotoRule(
    icon: AppIcons.centred,
    title: _r2t,
    body: _r2b,
    doLabel: _r2d,
    dontLabel: _r2n,
  ),
  PhotoRule(
    icon: AppIcons.bright,
    title: _r3t,
    body: _r3b,
    doLabel: _r3d,
    dontLabel: _r3n,
  ),
];

// Top-level functions so both lists above can stay `const`.
String _f1t(L l) => l.flow1Title;
String _f1b(L l) => l.flow1Body;
String _f1d(L l) => l.flow1Do;
String _f1n(L l) => l.flow1Dont;
String _f2t(L l) => l.flow2Title;
String _f2b(L l) => l.flow2Body;
String _f3t(L l) => l.flow3Title;
String _f3b(L l) => l.flow3Body;

String _r1t(L l) => l.rule1Title;
String _r1b(L l) => l.rule1Body;
String _r1d(L l) => l.rule1Do;
String _r1n(L l) => l.rule1Dont;
String _r2t(L l) => l.rule2Title;
String _r2b(L l) => l.rule2Body;
String _r2d(L l) => l.rule2Do;
String _r2n(L l) => l.rule2Dont;
String _r3t(L l) => l.rule3Title;
String _r3b(L l) => l.rule3Body;
String _r3d(L l) => l.rule3Do;
String _r3n(L l) => l.rule3Dont;
