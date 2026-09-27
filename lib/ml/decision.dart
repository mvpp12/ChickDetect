import 'classifier.dart';
import 'image_check.dart';

/// What the app is willing to tell the farmer.
enum VerdictKind {
  /// The photo never reached the model.
  photoRejected,

  /// The model answered but the answer did not clear its bar.
  inconclusive,

  /// A named condition, reported.
  condition,

  /// Nothing abnormal, reported.
  healthy,
}

/// Why a reading was held back. Shown to the farmer, not just logged.
enum HeldBackReason { lowConfidence, tooCloseToCall, healthyNeedsMore }

enum CertaintyBand { strong, likely, below }

/// The decision layer between the model and the screen.
///
/// The previous version reported whatever the model's top class was, as long
/// as it passed a single 0.65 threshold. Three things were wrong with that.
///
/// First, one threshold for all four classes treats a false "healthy" and a
/// false "salmonella" as equally costly. They are not. A wrong disease call
/// costs a vet visit; a wrong clean bill costs the flock, because the farmer
/// stops looking. So `healthy` is held to a higher bar.
///
/// Second, a top score says nothing about whether the model was *choosing*.
/// 0.70 against a runner-up of 0.68 is a coin toss wearing a confident number.
/// The margin between first and second place is checked separately.
///
/// Third, nothing checked the photo. That now happens before any of this.
class Decision {
  /// Bar for naming a condition.
  static const double conditionBar = 0.65;

  /// Bar for reporting a clean result. Higher for the reason above.
  static const double healthyBar = 0.85;

  /// Minimum gap between first and second place. Below this the model is
  /// picking between two classes rather than recognising one.
  static const double marginBar = 0.15;

  static double barFor(String label) =>
      label == 'healthy' ? healthyBar : conditionBar;

  static CertaintyBand bandFor(double confidence) {
    if (confidence >= 0.85) return CertaintyBand.strong;
    if (confidence >= conditionBar) return CertaintyBand.likely;
    return CertaintyBand.below;
  }

  /// Applies every gate and produces the verdict the UI renders.
  static Verdict evaluate({
    required PhotoQuality? quality,
    required Prediction? prediction,
  }) {
    if (quality != null && !quality.usable) {
      return Verdict(
        kind: VerdictKind.photoRejected,
        quality: quality,
        prediction: null,
        reasons: const <HeldBackReason>[],
      );
    }

    if (prediction == null) {
      return Verdict(
        kind: VerdictKind.inconclusive,
        quality: quality,
        prediction: null,
        reasons: const <HeldBackReason>[HeldBackReason.lowConfidence],
      );
    }

    final List<HeldBackReason> reasons = <HeldBackReason>[];
    final double bar = barFor(prediction.label);

    if (prediction.confidence < bar) {
      reasons.add(
        prediction.label == 'healthy'
            ? HeldBackReason.healthyNeedsMore
            : HeldBackReason.lowConfidence,
      );
    }
    if (prediction.margin < marginBar) {
      reasons.add(HeldBackReason.tooCloseToCall);
    }

    if (reasons.isNotEmpty) {
      return Verdict(
        kind: VerdictKind.inconclusive,
        quality: quality,
        prediction: prediction,
        reasons: reasons,
      );
    }

    return Verdict(
      kind: prediction.label == 'healthy'
          ? VerdictKind.healthy
          : VerdictKind.condition,
      quality: quality,
      prediction: prediction,
      reasons: const <HeldBackReason>[],
    );
  }
}

class Verdict {
  final VerdictKind kind;
  final PhotoQuality? quality;
  final Prediction? prediction;
  final List<HeldBackReason> reasons;

  const Verdict({
    required this.kind,
    required this.quality,
    required this.prediction,
    required this.reasons,
  });

  /// The condition key to look up in the knowledge base. Inconclusive and
  /// rejected photos resolve to their own entries, so every state has real
  /// guidance rather than an empty screen.
  String get conditionKey {
    switch (kind) {
      case VerdictKind.healthy:
        return 'healthy';
      case VerdictKind.condition:
        return prediction?.label ?? 'inconclusive';
      case VerdictKind.inconclusive:
      case VerdictKind.photoRejected:
        return 'inconclusive';
    }
  }

  /// Status used by the records list and its filters.
  String get status {
    switch (kind) {
      case VerdictKind.healthy:
        return 'healthy';
      case VerdictKind.condition:
        return 'disease';
      case VerdictKind.inconclusive:
      case VerdictKind.photoRejected:
        return 'inconclusive';
    }
  }

  double? get confidence => prediction?.confidence;
}
