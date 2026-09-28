import 'package:flutter/material.dart';

import '../../core/icons.dart';
import '../../core/strings.dart';
import '../../core/tokens.dart';
import '../../data/conditions.dart';
import '../../ml/decision.dart';
import '../../ml/image_check.dart';
import 'common.dart';

/// How much of the report to show.
enum ReportDepth {
  /// Straight after a scan: the verdict, how sure, and the first actions.
  /// Everything else is one tap away, because the minute after a scan is not
  /// when someone reads four sections.
  brief,

  /// The full record.
  full,
}

/// Everything the app can say about one finding.
///
/// Both the result sheet and the detail screen render this, so the two can
/// never disagree about what a result means — which they did in the previous
/// version, where the sheet and the detail screen had separate copies.
class ConditionReport extends StatelessWidget {
  final Condition condition;
  final double? confidence;
  final String? rawLabel;
  final Map<String, double>? scores;
  final PhotoQuality? quality;
  final List<HeldBackReason> heldBack;
  final ReportDepth depth;

  const ConditionReport({
    super.key,
    required this.condition,
    required this.depth,
    this.confidence,
    this.rawLabel,
    this.scores,
    this.quality,
    this.heldBack = const <HeldBackReason>[],
  });

  @override
  Widget build(BuildContext context) {
    final L l = L.of(context);
    final Lang lang = l.lang;
    final List<Widget> out = <Widget>[];

    // ── verdict ──────────────────────────────────────────────────────────
    out.add(
      VerdictCard(
        condition: condition,
        confidence: confidence,
        rawLabel: rawLabel,
      ),
    );

    // ── why it was held back ─────────────────────────────────────────────
    if (heldBack.isNotEmpty) {
      out
        ..add(const SizedBox(height: Insets.md))
        ..add(HeldBackCallout(reasons: heldBack));
    }

    // ── facts ────────────────────────────────────────────────────────────
    final List<Widget> facts = <Widget>[];
    if (condition.spread != null) {
      facts.add(
        FactTile(
          icon: AppIcons.spread,
          label: l.spread,
          value: condition.spread!(lang),
        ),
      );
    }
    if (condition.zoonotic != null) {
      facts.add(
        FactTile(
          icon: AppIcons.people,
          label: l.riskToPeople,
          value: condition.zoonotic!(lang),
        ),
      );
    }
    if (facts.isNotEmpty) {
      out
        ..add(const SizedBox(height: Insets.md))
        ..add(
          // IntrinsicHeight gives `stretch` a finite height to stretch to.
          // Without it, inside a scroll view the row asked for infinite
          // height and every report with these facts failed to lay out.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (int i = 0; i < facts.length; i++) ...<Widget>[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(child: facts[i]),
                ],
              ],
            ),
          ),
        );
    }

    // ── the law ──────────────────────────────────────────────────────────
    if (condition.law != null) {
      out
        ..add(const SizedBox(height: Insets.md))
        ..add(
          Callout(
            icon: AppIcons.law,
            title: l.requiredByLaw,
            body: condition.law!(lang),
            ink: AppColor.caution,
            fill: AppColor.cautionSoft,
          ),
        );
    }

    // ── first actions ────────────────────────────────────────────────────
    final bool hasDay = condition.firstDay.isNotEmpty;
    final List<ActionStep> opening = hasDay
        ? condition.firstDay
        : condition.thisWeek;

    if (depth == ReportDepth.brief) {
      if (opening.isNotEmpty) {
        out
          ..add(const SizedBox(height: Insets.section))
          ..add(
            SectionHead(
              icon: hasDay ? AppIcons.firstDay : AppIcons.thisWeek,
              label: hasDay ? l.first24 : l.thisWeek,
            ),
          )
          ..add(
            StepRail(
              steps: opening.take(3).toList(growable: false),
              accent: AppColor.steps,
            ),
          );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: out,
      );
    }

    // ── full depth ───────────────────────────────────────────────────────
    out
      ..add(const SizedBox(height: Insets.section))
      ..add(SectionHead(icon: AppIcons.about, label: l.whatThisIs))
      ..add(Text(condition.detail(lang), style: AppFont.body));

    if (condition.signs.isNotEmpty) {
      out
        ..add(const SizedBox(height: Insets.section))
        ..add(SectionHead(icon: AppIcons.lookFor, label: l.whatToLookFor))
        ..add(SignTabs(groups: condition.signs, accent: AppColor.ink3));
    }

    if (condition.firstDay.isNotEmpty) {
      out
        ..add(const SizedBox(height: Insets.section))
        ..add(SectionHead(icon: AppIcons.firstDay, label: l.first24))
        ..add(StepRail(steps: condition.firstDay, accent: AppColor.steps));
    }

    if (condition.thisWeek.isNotEmpty) {
      out
        ..add(const SizedBox(height: Insets.section))
        ..add(SectionHead(icon: AppIcons.thisWeek, label: l.thisWeek))
        ..add(StepRail(steps: condition.thisWeek, accent: AppColor.steps));
    }

    if (condition.neverDo.isNotEmpty) {
      out
        ..add(const SizedBox(height: Insets.section))
        ..add(
          Callout(
            icon: AppIcons.neverDo,
            title: l.neverDo,
            bullets: condition.neverDo
                .map((Say s) => s(lang))
                .toList(growable: false),
            ink: AppColor.danger,
            fill: AppColor.dangerSoft,
          ),
        );
    }

    out
      ..add(const SizedBox(height: Insets.section))
      ..add(SectionHead(icon: AppIcons.getHelp, label: l.whenToCall))
      ..add(
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(condition.escalate(lang), style: AppFont.body),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              // The disclaimer lives here and nowhere else. Repeating it on
              // every screen taught people to stop reading it.
              Text(
                l.notADiagnosis,
                style: AppFont.bodySm.copyWith(color: AppColor.ink2),
              ),
            ],
          ),
        ),
      );

    if (quality != null) {
      out
        ..add(const SizedBox(height: Insets.section))
        ..add(
          SectionHead(
            icon: AppIcons.photoQuality,
            label: l.photoQuality,
            color: AppColor.ink3,
          ),
        )
        ..add(QualityPanel(quality: quality!));
    }

    if (scores != null && scores!.isNotEmpty) {
      out
        ..add(const SizedBox(height: Insets.section))
        ..add(
          SectionHead(
            icon: AppIcons.scores,
            label: l.howScored,
            color: AppColor.ink3,
          ),
        )
        ..add(ScoreBars(scores: scores!, top: rawLabel))
        ..add(const SizedBox(height: 6))
        ..add(
          Row(
            children: <Widget>[
              const Icon(AppIcons.onDevice, size: 14, color: AppColor.ink3),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  l.analysedHere,
                  style: AppFont.labelSm.copyWith(color: AppColor.ink3),
                ),
              ),
            ],
          ),
        );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: out);
  }
}

class VerdictCard extends StatelessWidget {
  final Condition condition;
  final double? confidence;
  final String? rawLabel;

  /// False where the name is already on screen — the scan details page keeps
  /// it in the strip above the tabs, and printing it twice was just noise.
  final bool showName;

  const VerdictCard({
    super.key,
    required this.condition,
    required this.confidence,
    required this.rawLabel,
    this.showName = true,
  });

  @override
  Widget build(BuildContext context) {
    final L l = L.of(context);
    final Color ink = severityInk(condition);
    final double bar = Decision.barFor(rawLabel ?? '');
    final double value = confidence ?? 0;
    final bool passed = value >= bar;

    final String band = switch (Decision.bandFor(value)) {
      CertaintyBand.strong => l.strongMatch,
      CertaintyBand.likely => l.likelyMatch,
      CertaintyBand.below => l.belowBar,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Insets.card + 2),
      decoration: BoxDecoration(
        color: severityFill(condition),
        borderRadius: BorderRadius.circular(Insets.rXl),
        border: Border.all(color: ink.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (showName) ...<Widget>[
            Row(
              children: <Widget>[
                Icon(severityIcon(condition), color: ink, size: 26),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    condition.name(l.lang),
                    style: AppFont.display.copyWith(color: ink),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
          ],
          Text(
            condition.headline(l.lang),
            style: showName ? AppFont.label : AppFont.h3.copyWith(color: ink),
          ),
          if (confidence != null) ...<Widget>[
            const SizedBox(height: Insets.md),
            CertaintyMeter(
              value: value,
              bar: bar,
              bandLabel: band,
              passed: passed,
              ink: ink,
            ),
          ],
        ],
      ),
    );
  }
}

/// Says out loud why a reading was not reported.
///
/// The previous version simply showed "Inconclusive" and left the farmer to
/// guess whether that meant the photo, the bird, or the app. Naming the reason
/// is what makes the next attempt better.
class HeldBackCallout extends StatelessWidget {
  final List<HeldBackReason> reasons;

  const HeldBackCallout({super.key, required this.reasons});

  @override
  Widget build(BuildContext context) {
    final Lang lang = L.of(context).lang;
    String text(HeldBackReason r) => switch (r) {
      HeldBackReason.lowConfidence =>
        lang == Lang.tl
            ? 'Hindi pa sapat na malinaw ang resulta para sa litratong ito.'
            : 'The result for this photo is not clear enough yet.',
      HeldBackReason.tooCloseToCall =>
        lang == Lang.tl
            ? 'Dalawang sakit ang halos pareho ang score, kaya hindi ito '
                  'makapili nang tama.'
            : 'Two sicknesses scored almost the same, so it cannot pick the '
                  'right one.',
      HeldBackReason.healthyNeedsMore =>
        lang == Lang.tl
            ? 'Mas mahigpit ang app bago sabihing malusog, dahil mas delikado '
                  'kung mali ang "walang sakit".'
            : 'The app is stricter before saying healthy, because a wrong '
                  '"no sickness" is the more dangerous mistake.',
    };

    return Callout(
      icon: AppIcons.info,
      title: lang == Lang.tl
          ? 'Bakit kailangang kunan ulit'
          : 'Why take another photo',
      bullets: reasons.map(text).toList(growable: false),
      crossBullets: false,
      ink: AppColor.info,
      fill: AppColor.infoSoft,
    );
  }
}

class FactTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const FactTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    decoration: BoxDecoration(
      color: AppColor.surface,
      borderRadius: BorderRadius.circular(Insets.rSm),
      border: Border.all(color: AppColor.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(icon, size: 14, color: AppColor.ink2),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label.toUpperCase(),
                style: AppFont.micro.copyWith(color: AppColor.ink2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(value, style: AppFont.bodySm),
      ],
    ),
  );
}

class QualityPanel extends StatelessWidget {
  final PhotoQuality quality;

  const QualityPanel({super.key, required this.quality});

  @override
  Widget build(BuildContext context) {
    final L l = L.of(context);
    return AppCard(
      child: Column(
        children: <Widget>[
          MiniMeter(
            label: l.sharpness,
            value: quality.sharpnessScore,
            readout: quality.sharpness.toStringAsFixed(0),
          ),
          MiniMeter(
            label: l.brightness,
            value: quality.brightnessScore,
            readout: quality.brightness.toStringAsFixed(0),
          ),
          MiniMeter(
            label: l.detail,
            value: quality.spreadScore,
            readout: quality.spread.toStringAsFixed(0),
          ),
        ],
      ),
    );
  }
}

class ScoreBars extends StatelessWidget {
  final Map<String, double> scores;
  final String? top;

  const ScoreBars({super.key, required this.scores, this.top});

  @override
  Widget build(BuildContext context) {
    final Lang lang = L.of(context).lang;
    final List<MapEntry<String, double>> rows = scores.entries.toList()
      ..sort(
        (MapEntry<String, double> a, MapEntry<String, double> b) =>
            b.value.compareTo(a.value),
      );

    return Column(
      children: rows
          .map((MapEntry<String, double> e) {
            final bool isTop =
                top != null && e.key.toLowerCase() == top!.toLowerCase();
            final Color ink = isTop ? AppColor.green700 : AppColor.ink3;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          conditionFor(e.key).name(lang),
                          style: AppFont.bodySm.copyWith(
                            color: isTop ? AppColor.ink : AppColor.ink2,
                            fontWeight: isTop
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      Text(
                        '${(e.value * 100).toStringAsFixed(1)}%',
                        style: AppFont.labelSm.copyWith(color: ink),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(Insets.rFull),
                    child: LinearProgressIndicator(
                      value: e.value.clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: AppColor.fill,
                      valueColor: AlwaysStoppedAnimation<Color>(ink),
                    ),
                  ),
                ],
              ),
            );
          })
          .toList(growable: false),
    );
  }
}
