import 'package:flutter/material.dart';

import '../core/icons.dart';
import '../core/strings.dart';
import '../core/tokens.dart';
import '../data/conditions.dart';
import '../data/photo_rules.dart';
import 'guide_intro_page.dart';
import 'widgets/common.dart';
import 'widgets/report.dart';

/// Reference: the capture rules, what the app can and cannot do, and the
/// conditions it knows.
///
/// The rules here are the same [kPhotoRules] the first-run guide walks — one
/// source, so the two can never teach different things. The previous version
/// had a three-slide onboarding and a separate four-card Tips tab that
/// overlapped by about half.
class GuidePage extends StatelessWidget {
  const GuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    final L l = L.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Insets.screen,
        Insets.sm,
        Insets.screen,
        Insets.xxl,
      ),
      children: <Widget>[
        PageTitle(title: l.guideTab, subtitle: l.guideTabSub),

        // ── the three rules ────────────────────────────────────────────
        SectionHead(
          icon: AppIcons.scan,
          label: l.photoRules,
        ),
        ...kPhotoRules.map((PhotoRule r) => _RuleCard(rule: r)),
        const SizedBox(height: 4),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const GuideIntroPage()),
          ),
          icon: const Icon(AppIcons.replay, size: 20),
          label: Text(l.replayGuide),
        ),

        // ── what it cannot do ──────────────────────────────────────────
        const SizedBox(height: Insets.section),
        Callout(
          icon: AppIcons.info,
          title: l.limitsTitle,
          body: l.limitsBody,
          ink: AppColor.info,
          fill: AppColor.infoSoft,
        ),

        // ── the conditions ─────────────────────────────────────────────
        const SizedBox(height: Insets.section),
        SectionHead(
          icon: AppIcons.conditions,
          label: l.conditionsCovered,
        ),
        Text(
          l.conditionsCoveredSub,
          style: AppFont.bodySm.copyWith(color: AppColor.ink2),
        ),
        const SizedBox(height: Insets.md),
        ...kNamedConditions.map(
          (String key) => _ConditionCard(condition: kConditions[key]!),
        ),
        _ConditionCard(condition: kConditions['healthy']!),
      ],
    );
  }
}

class _RuleCard extends StatelessWidget {
  final PhotoRule rule;

  const _RuleCard({required this.rule});

  @override
  Widget build(BuildContext context) {
    final L l = L.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColor.mintSoft,
                borderRadius: BorderRadius.circular(Insets.rSm),
              ),
              child: Icon(rule.icon, size: 19, color: AppColor.green900),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(rule.title(l), style: AppFont.h3),
                  const SizedBox(height: 5),
                  Text(
                    rule.body(l),
                    style: AppFont.bodySm.copyWith(color: AppColor.ink2),
                  ),
                  const SizedBox(height: 11),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: <Widget>[
                      DoDont(label: rule.doLabel(l), good: true),
                      DoDont(label: rule.dontLabel(l), good: false),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One condition, expandable into the full reference.
class _ConditionCard extends StatefulWidget {
  final Condition condition;

  const _ConditionCard({required this.condition});

  @override
  State<_ConditionCard> createState() => _ConditionCardState();
}

class _ConditionCardState extends State<_ConditionCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final L l = L.of(context);
    final Condition c = widget.condition;
    final Color ink = severityInk(c);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColor.surface,
          borderRadius: BorderRadius.circular(Insets.rLg),
          border: Border.all(color: AppColor.line),
        ),
        child: Column(
          children: <Widget>[
            InkWell(
              onTap: () => setState(() => _open = !_open),
              child: Semantics(
                button: true,
                expanded: _open,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 60),
                  padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: severityFill(c),
                          borderRadius: BorderRadius.circular(Insets.rSm),
                        ),
                        child: Icon(severityIcon(c), size: 19, color: ink),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(c.name(l.lang), style: AppFont.h3),
                            const SizedBox(height: 2),
                            Text(
                              c.headline(l.lang),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppFont.labelSm
                                  .copyWith(color: AppColor.ink3),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedRotation(
                        turns: _open ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(
                          AppIcons.expand,
                          size: 20,
                          color: AppColor.ink3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: !_open
                  ? const SizedBox(width: double.infinity)
                  : Container(
                width: double.infinity,
                color: AppColor.bg,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                // Reference reading, so the full report without the parts that
                // only make sense attached to an actual scan.
                child: ConditionReport(
                  condition: c,
                  depth: ReportDepth.full,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
