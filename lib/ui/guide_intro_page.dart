import 'package:flutter/material.dart';

import '../core/icons.dart';
import '../core/strings.dart';
import '../core/tokens.dart';
import '../data/photo_rules.dart';
import 'widgets/common.dart';

/// The first-run walkthrough: an opening card, then the three steps.
///
/// Each step sits on the photograph that shows it — aiming at a sample, the
/// model reading it on the phone, and the result. The capture *rules* live in
/// the Guide tab instead, where they can be looked up rather than remembered
/// from a screen seen once.
class GuideIntroPage extends StatefulWidget {
  /// Called when the farmer finishes or skips. Null when replayed from the
  /// Guide tab, in which case the page simply pops.
  final VoidCallback? onDone;

  const GuideIntroPage({super.key, this.onDone});

  @override
  State<GuideIntroPage> createState() => _GuideIntroPageState();
}

class _GuideIntroPageState extends State<GuideIntroPage> {
  final PageController _pages = PageController();

  /// -1 is the opening card; 0..2 are the rules.
  int _index = -1;

  bool get _isReplay => widget.onDone == null;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _finish() {
    if (_isReplay) {
      Navigator.of(context).pop();
    } else {
      widget.onDone!.call();
    }
  }

  void _advance() {
    if (_index == -1) {
      setState(() => _index = 0);
      return;
    }
    if (_index < kFlowSteps.length - 1) {
      _pages.nextPage(
        duration: const Duration(milliseconds: 340),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final L l = L.of(context);

    return Scaffold(
      backgroundColor: AppColor.bg,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _TopBar(
              label: _index < 0
                  ? l.guideEyebrow
                  : '${l.step} ${_index + 1} ${l.stepOf} ${kFlowSteps.length}',
              actionLabel: _isReplay ? l.close : l.skip,
              onAction: _finish,
            ),
            Expanded(
              child: _index < 0
                  ? _Opening(l: l)
                  : PageView.builder(
                      controller: _pages,
                      itemCount: kFlowSteps.length,
                      onPageChanged: (int i) => setState(() => _index = i),
                      itemBuilder: (BuildContext context, int i) =>
                          _RuleView(rule: kFlowSteps[i], l: l),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Insets.screen,
                Insets.md,
                Insets.screen,
                Insets.lg,
              ),
              child: Column(
                children: <Widget>[
                  if (_index >= 0) ...<Widget>[
                    _Dots(count: kFlowSteps.length, active: _index),
                    const SizedBox(height: Insets.md),
                  ],
                  ElevatedButton(
                    onPressed: _advance,
                    child: Text(
                      _index < 0
                          ? l.startGuide
                          : _index == kFlowSteps.length - 1
                          ? l.startScanning
                          : l.next,
                    ),
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

class _TopBar extends StatelessWidget {
  final String label;
  final String actionLabel;
  final VoidCallback onAction;

  const _TopBar({
    required this.label,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 56),
    padding: const EdgeInsets.only(left: Insets.screen, right: Insets.sm),
    child: Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label.toUpperCase(),
            style: AppFont.micro.copyWith(color: AppColor.green700),
          ),
        ),
        TextButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    ),
  );
}

class _Opening extends StatelessWidget {
  final L l;

  const _Opening({required this.l});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: Insets.screen),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: Insets.sm),
        Text(l.guideTitle, style: AppFont.display),
        const SizedBox(height: 12),
        Text(l.guideIntro, style: AppFont.body.copyWith(color: AppColor.ink2)),
        const SizedBox(height: Insets.lg),
        ...List<Widget>.generate(kFlowSteps.length, (int i) {
          final FlowStep step = kFlowSteps[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColor.mintSoft,
                      borderRadius: BorderRadius.circular(Insets.rSm),
                    ),
                    child: Text(
                      '${i + 1}',
                      style: AppFont.h3.copyWith(color: AppColor.green900),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(child: Text(step.title(l), style: AppFont.h3)),
                ],
              ),
            ),
          );
        }),
      ],
    ),
  );
}

/// One step, sitting on its photograph.
class _RuleView extends StatelessWidget {
  final FlowStep rule;
  final L l;

  const _RuleView({required this.rule, required this.l});

  @override
  Widget build(BuildContext context) {
    final String? good = rule.doLabel?.call(l);
    final String? bad = rule.dontLabel?.call(l);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: Insets.screen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // The photographs are 1376x768. Holding that ratio keeps the hand
          // and the phone inside the frame; cropping to a tall box cut both.
          ClipRRect(
            borderRadius: BorderRadius.circular(Insets.rXl),
            child: AspectRatio(
              aspectRatio: 1376 / 768,
              child: Image.asset(
                rule.asset,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
                // An illustration is never worth a crash.
                errorBuilder: (_, _, _) => const ColoredBox(
                  color: AppColor.mintSoft,
                  child: Center(
                    child: Icon(
                      AppIcons.image,
                      size: 48,
                      color: AppColor.green700,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: Insets.lg),
          Text(rule.title(l), style: AppFont.display),
          const SizedBox(height: 10),
          Text(rule.body(l), style: AppFont.body.copyWith(color: AppColor.ink2)),
          if (good != null && bad != null) ...<Widget>[
            const SizedBox(height: Insets.md),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                DoDont(label: good, good: true),
                DoDont(label: bad, good: false),
              ],
            ),
          ],
          const SizedBox(height: Insets.md),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  final int count;
  final int active;

  const _Dots({required this.count, required this.active});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List<Widget>.generate(count, (int i) {
      final bool on = i == active;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 3.5),
        width: on ? 22 : 7,
        height: 7,
        decoration: BoxDecoration(
          color: on ? AppColor.green700 : AppColor.mintLine,
          borderRadius: BorderRadius.circular(Insets.rFull),
        ),
      );
    }),
  );
}
