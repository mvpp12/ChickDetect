import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
///
/// The steps use the whole screen: the photograph runs edge to edge across
/// the top half and fades into the page, the words sit under it, and the
/// buttons stay at the bottom — no dead band between content and controls.
/// Progress is shown once, as a segmented bar over the photo; the old
/// "STEP 1 OF 3" label and the dots under the content said it twice.
class GuideIntroPage extends StatefulWidget {
  /// Called when the farmer finishes or skips. Null when replayed from the
  /// Guide tab, in which case the page simply pops.
  final VoidCallback? onDone;

  const GuideIntroPage({super.key, this.onDone});

  @override
  State<GuideIntroPage> createState() => _GuideIntroPageState();
}

class _GuideIntroPageState extends State<GuideIntroPage> {
  /// -1 is the opening card; 0..2 are the steps.
  int _index = -1;

  /// Which way the last move went, so the text slides in from the right side.
  bool _forward = true;

  bool get _isReplay => widget.onDone == null;
  bool get _isLast => _index == kFlowSteps.length - 1;

  void _finish() {
    if (_isReplay) {
      Navigator.of(context).pop();
    } else {
      widget.onDone!.call();
    }
  }

  void _next() {
    if (_isLast) {
      _finish();
      return;
    }
    setState(() {
      _forward = true;
      _index++;
    });
  }

  void _back() {
    if (_index < 0) return;
    setState(() {
      _forward = false;
      _index--;
    });
  }

  /// A swipe still works for people who expect it, but nothing depends on it.
  void _onSwipe(DragEndDetails d) {
    final double v = d.primaryVelocity ?? 0;
    if (v < -250) _next();
    if (v > 250 && _index > 0) _back();
  }

  @override
  Widget build(BuildContext context) {
    final L l = L.of(context);

    if (_index < 0) {
      return _OpeningScreen(
        l: l,
        actionLabel: _isReplay ? l.close : l.skip,
        onAction: _finish,
        onStart: _next,
      );
    }

    final FlowStep step = kFlowSteps[_index];
    final double photoHeight = (MediaQuery.of(context).size.height * 0.46)
        .clamp(260.0, 440.0);

    // Light status-bar icons, because the photograph runs up behind them.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColor.bg,
        body: GestureDetector(
          onHorizontalDragEnd: _onSwipe,
          child: Column(
            children: <Widget>[
              SizedBox(
                height: photoHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    // The photo crossfades between steps.
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      // Expand, or the photo keeps its own shape and floats
                      // in the middle with bands above and below it.
                      layoutBuilder: (Widget? current, List<Widget> previous) =>
                          Stack(
                            fit: StackFit.expand,
                            children: <Widget>[...previous, ?current],
                          ),
                      child: _Photo(
                        key: ValueKey<int>(_index),
                        asset: step.asset,
                      ),
                    ),
                    // Scrims: dark at the top so the bar and button read over
                    // any photo; page-coloured at the bottom so the photo
                    // fades into the page instead of stopping at an edge.
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: <double>[0, 0.28, 0.72, 1],
                          colors: <Color>[
                            Color(0x8C000000),
                            Color(0x00000000),
                            Color(0x00F6F8FA),
                            AppColor.bg,
                          ],
                        ),
                      ),
                    ),
                    SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          Insets.screen,
                          10,
                          10,
                          0,
                        ),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            children: <Widget>[
                              Expanded(
                                child: _Progress(
                                  count: kFlowSteps.length,
                                  active: _index,
                                  label:
                                      '${l.step} ${_index + 1} '
                                      '${l.stepOf} ${kFlowSteps.length}',
                                ),
                              ),
                              const SizedBox(width: 10),
                              _GlassButton(
                                label: _isReplay ? l.close : l.skip,
                                onTap: _finish,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // The words slide in from the side they are coming from.
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (Widget child, Animation<double> a) {
                    final bool incoming = child.key == ValueKey<int>(_index);
                    final double from = (_forward == incoming) ? 0.08 : -0.08;
                    return FadeTransition(
                      opacity: a,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: Offset(from, 0),
                          end: Offset.zero,
                        ).animate(a),
                        child: child,
                      ),
                    );
                  },
                  layoutBuilder: (Widget? current, List<Widget> previous) =>
                      Stack(
                        alignment: Alignment.topLeft,
                        children: <Widget>[...previous, ?current],
                      ),
                  child: _StepText(
                    key: ValueKey<int>(_index),
                    step: step,
                    l: l,
                  ),
                ),
              ),

              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Insets.screen,
                    Insets.sm,
                    Insets.screen,
                    Insets.md,
                  ),
                  child: Row(
                    children: <Widget>[
                      SizedBox(
                        width: 120,
                        child: OutlinedButton(
                          onPressed: _back,
                          child: Text(l.back),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _next,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Flexible(
                                child: Text(
                                  _isLast ? l.startScanning : l.next,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                _isLast ? AppIcons.scan : AppIcons.chevron,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  final String asset;

  const _Photo({super.key, required this.asset});

  @override
  Widget build(BuildContext context) => Image.asset(
    asset,
    fit: BoxFit.cover,
    // Every photograph keeps its phone near the middle, so a centred crop
    // keeps the hand, the phone and the sample in frame.
    alignment: Alignment.center,
    // The source files are 1376 px wide; decoding them at screen width is
    // plenty and spares a cheap phone a few megabytes per step.
    cacheWidth: 1100,
    filterQuality: FilterQuality.medium,
    // An illustration is never worth a crash.
    errorBuilder: (_, _, _) => const ColoredBox(
      color: AppColor.mintSoft,
      child: Center(
        child: Icon(AppIcons.image, size: 48, color: AppColor.green700),
      ),
    ),
  );
}

/// Three segments, filled up to the current step. Over the photo, so white.
class _Progress extends StatelessWidget {
  final int count;
  final int active;
  final String label;

  const _Progress({
    required this.count,
    required this.active,
    required this.label,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    excludeSemantics: true,
    child: Row(
      children: List<Widget>.generate(count, (int i) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == count - 1 ? 0 : 6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Insets.rFull),
              child: Container(
                height: 4,
                color: const Color(0x59FFFFFF),
                alignment: Alignment.centerLeft,
                child: AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  widthFactor: i <= active ? 1 : 0,
                  // Without a height factor the fill gets no height at all
                  // and the bar looks permanently empty.
                  heightFactor: 1,
                  child: const ColoredBox(color: Colors.white),
                ),
              ),
            ),
          ),
        );
      }),
    ),
  );
}

/// A small translucent pill that stays readable over any photograph.
class _GlassButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _GlassButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0x66000000),
    borderRadius: BorderRadius.circular(Insets.rFull),
    child: InkWell(
      borderRadius: BorderRadius.circular(Insets.rFull),
      onTap: onTap,
      // No `alignment` here: with one, the pill grows to fill all the height
      // it is offered and turns into a tall bar down the photo.
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Text(label, style: AppFont.label.copyWith(color: Colors.white)),
      ),
    ),
  );
}

/// Title, body and — on the step that has one — the do/avoid comparison.
class _StepText extends StatelessWidget {
  final FlowStep step;
  final L l;

  const _StepText({super.key, required this.step, required this.l});

  @override
  Widget build(BuildContext context) {
    final String? good = step.doLabel?.call(l);
    final String? bad = step.dontLabel?.call(l);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        Insets.screen,
        4,
        Insets.screen,
        Insets.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(step.title(l), style: AppFont.display),
          const SizedBox(height: 10),
          Text(
            step.body(l),
            style: AppFont.body.copyWith(color: AppColor.ink2, fontSize: 15),
          ),
          if (good != null && bad != null) ...<Widget>[
            const SizedBox(height: Insets.lg),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(
                    child: _Compare(good: true, label: good, l: l),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Compare(good: false, label: bad, l: l),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One half of the do / avoid pair, large enough to read at arm's length in
/// daylight — the old pale chips at 11 pt were the hardest thing on the screen
/// to read, and the most useful.
class _Compare extends StatelessWidget {
  final bool good;
  final String label;
  final L l;

  const _Compare({required this.good, required this.label, required this.l});

  @override
  Widget build(BuildContext context) {
    final Color ink = good ? AppColor.green700 : AppColor.danger;
    final Color fill = good ? AppColor.mintSoft : AppColor.dangerSoft;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(Insets.rMd),
        border: Border.all(color: ink.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(color: ink, shape: BoxShape.circle),
                child: Icon(
                  good ? AppIcons.check : AppIcons.cross,
                  size: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                (good ? l.doThis : l.avoidThis).toUpperCase(),
                style: AppFont.micro.copyWith(color: ink, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(label, style: AppFont.h3.copyWith(color: AppColor.ink)),
        ],
      ),
    );
  }
}

/// The card before the steps: what the walkthrough covers, in three lines.
class _OpeningScreen extends StatelessWidget {
  final L l;
  final String actionLabel;
  final VoidCallback onAction;
  final VoidCallback onStart;

  const _OpeningScreen({
    required this.l,
    required this.actionLabel,
    required this.onAction,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColor.bg,
    body: SafeArea(
      child: Column(
        children: <Widget>[
          Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.only(
              left: Insets.screen,
              right: Insets.sm,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    l.guideEyebrow.toUpperCase(),
                    // Grey, not green: on this screen green means "tap me",
                    // and only the Skip button beside it can be tapped.
                    style: AppFont.micro.copyWith(color: AppColor.ink3),
                  ),
                ),
                TextButton(onPressed: onAction, child: Text(actionLabel)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: Insets.screen),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(height: Insets.sm),
                  Text(l.guideTitle, style: AppFont.display),
                  const SizedBox(height: 12),
                  Text(
                    l.guideIntro,
                    style: AppFont.body.copyWith(color: AppColor.ink2),
                  ),
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
                                style: AppFont.h3.copyWith(
                                  color: AppColor.green900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Text(step.title(l), style: AppFont.h3),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Insets.screen,
              Insets.md,
              Insets.screen,
              Insets.lg,
            ),
            child: ElevatedButton(
              onPressed: onStart,
              child: Text(l.startGuide),
            ),
          ),
        ],
      ),
    ),
  );
}
