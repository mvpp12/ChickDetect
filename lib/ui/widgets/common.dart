import 'package:flutter/material.dart';

import '../../core/icons.dart';
import '../../core/strings.dart';
import '../../core/tokens.dart';
import '../../data/conditions.dart';

Color severityInk(Condition c) {
  if (c.isHealthy) return AppColor.green700;
  switch (c.severity) {
    case Severity.high:
      return AppColor.danger;
    case Severity.watch:
      return AppColor.caution;
    case Severity.none:
      return AppColor.green700;
  }
}

Color severityFill(Condition c) {
  if (c.isHealthy) return AppColor.mintSoft;
  switch (c.severity) {
    case Severity.high:
      return AppColor.dangerSoft;
    case Severity.watch:
      return AppColor.cautionSoft;
    case Severity.none:
      return AppColor.mintSoft;
  }
}

Color statusInk(String status) => switch (status) {
  'healthy' => AppColor.green700,
  'disease' => AppColor.danger,
  _ => AppColor.caution,
};

/// The glyph that goes with a status, so a result is never told by colour
/// alone.
IconData statusIcon(String status) => switch (status) {
  'healthy' => AppIcons.healthy,
  'disease' => AppIcons.serious,
  _ => AppIcons.unsure,
};

IconData severityIcon(Condition c) {
  if (c.isHealthy) return AppIcons.healthy;
  return c.severity == Severity.high ? AppIcons.serious : AppIcons.unsure;
}

/// One snackbar style, replacing the copies each page used to carry.
void showToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// The confirmation every irreversible action goes through. The action button
/// names the action ("Delete"), never "OK", and is the only red thing on it.
Future<bool> confirmDestructive(
  BuildContext context, {
  required String title,
  required String body,
  required String action,
}) async {
  final L l = L.of(context);
  final bool? yes = await showDialog<bool>(
    context: context,
    builder: (BuildContext ctx) => AlertDialog(
      icon: const Icon(AppIcons.delete, color: AppColor.danger, size: 28),
      title: Text(title, textAlign: TextAlign.center),
      content: Text(body, textAlign: TextAlign.center),
      actionsAlignment: MainAxisAlignment.center,
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l.cancel),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: AppColor.danger),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(action),
        ),
      ],
    ),
  );
  return yes == true;
}

/// A pill-shaped segmented control.
///
/// Records' time window and Settings' language picker were two hand-built
/// copies of this with slightly different heights and shadows.
class Segmented<T> extends StatelessWidget {
  final T value;
  final ValueChanged<T> onChanged;
  final List<(T, String)> options;
  final double height;

  const Segmented({
    super.key,
    required this.value,
    required this.onChanged,
    required this.options,
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: AppColor.fill,
      borderRadius: BorderRadius.circular(Insets.rFull),
    ),
    child: Row(
      children: options.map(((T, String) o) {
        final bool on = o.$1 == value;
        return Expanded(
          child: Semantics(
            selected: on,
            button: true,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: on ? AppColor.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(Insets.rFull),
                boxShadow: on
                    ? <BoxShadow>[
                        BoxShadow(
                          color: AppColor.ink.withValues(alpha: 0.10),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  borderRadius: BorderRadius.circular(Insets.rFull),
                  onTap: () => onChanged(o.$1),
                  child: Container(
                    constraints: BoxConstraints(minHeight: height - 6),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      o.$2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFont.label.copyWith(
                        color: on ? AppColor.green900 : AppColor.ink2,
                        fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(growable: false),
    ),
  );
}

/// A plain surface. Border, not shadow — a shadow on every block flattens the
/// hierarchy, and the few things that need lifting use one deliberately.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? border;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Insets.card),
    this.color,
    this.border,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: color ?? AppColor.surface,
      borderRadius: BorderRadius.circular(Insets.rLg),
      border: Border.all(color: border ?? AppColor.line),
    ),
    child: child,
  );
}

/// Screen title, printed in the scroll so it can carry a subtitle.
class PageTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const PageTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Insets.md),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: AppFont.h1),
              if (subtitle != null) ...<Widget>[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: AppFont.bodySm.copyWith(color: AppColor.ink3),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...<Widget>[
          const SizedBox(width: 10),
          trailing!,
        ],
      ],
    ),
  );
}

/// Heading inside a report.
class SectionHead extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const SectionHead({
    super.key,
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Insets.md),
    child: Row(
      children: <Widget>[
        Icon(icon, size: 19, color: color ?? AppColor.ink),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: AppFont.h3)),
      ],
    ),
  );
}

/// The green tick / red cross pair.
class DoDont extends StatelessWidget {
  final String label;
  final bool good;

  const DoDont({super.key, required this.label, required this.good});

  @override
  Widget build(BuildContext context) {
    final Color ink = good ? AppColor.green900 : AppColor.danger;
    final Color fill = good ? AppColor.mintSoft : AppColor.dangerSoft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(Insets.rFull),
        border: Border.all(color: ink.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(good ? AppIcons.check : AppIcons.cross,
              size: 14, color: ink),
          const SizedBox(width: 6),
          Flexible(
            child: Text(label, style: AppFont.labelSm.copyWith(color: ink)),
          ),
        ],
      ),
    );
  }
}

/// Small filled pill.
class Pill extends StatelessWidget {
  final String label;
  final Color ink;
  final Color fill;
  final IconData? icon;

  const Pill({
    super.key,
    required this.label,
    required this.ink,
    required this.fill,
    this.icon,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: fill,
      borderRadius: BorderRadius.circular(Insets.rFull),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (icon != null) ...<Widget>[
          Icon(icon, size: 12, color: ink),
          const SizedBox(width: 5),
        ],
        Text(label, style: AppFont.labelSm.copyWith(color: ink)),
      ],
    ),
  );
}

/// The certainty bar, with a marker at the bar the scan had to clear.
///
/// The marker is the whole point. A bar on its own tells a farmer nothing —
/// they cannot know whether two-thirds full is good. With the threshold drawn
/// on it, a short bar reads as "did not reach it", which is the actual meaning,
/// and the percentage never has to appear.
class CertaintyMeter extends StatelessWidget {
  final double value;
  final double bar;
  final String bandLabel;
  final bool passed;

  /// Colour of a bar that cleared the threshold — the verdict's own colour.
  /// It used to be green regardless, which on a Newcastle result read as
  /// "healthy" at a glance.
  final Color? ink;

  const CertaintyMeter({
    super.key,
    required this.value,
    required this.bar,
    required this.bandLabel,
    required this.passed,
    this.ink,
  });

  @override
  Widget build(BuildContext context) {
    final L l = L.of(context);
    final Color ink =
        passed ? (this.ink ?? AppColor.green700) : AppColor.caution;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Text(
              l.certainty,
              style: AppFont.labelSm.copyWith(color: AppColor.ink2),
            ),
            const Spacer(),
            Text(bandLabel, style: AppFont.label.copyWith(color: ink)),
          ],
        ),
        const SizedBox(height: 9),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints c) {
            final double w = c.maxWidth;
            final double markX = (w * bar).clamp(0.0, w);
            return SizedBox(
              height: 32,
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColor.ink.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(Insets.rFull),
                    ),
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: value.clamp(0.0, 1.0)),
                    duration: const Duration(milliseconds: 620),
                    curve: Curves.easeOutCubic,
                    builder: (BuildContext _, double v, Widget? _) =>
                        Container(
                          height: 10,
                          width: w * v,
                          decoration: BoxDecoration(
                            color: ink,
                            borderRadius:
                                BorderRadius.circular(Insets.rFull),
                          ),
                        ),
                  ),
                  Positioned(
                    left: markX - 1,
                    top: -4,
                    child: Container(
                      width: 2,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColor.ink,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Wide enough for "KAILANGAN" on one line; at 60px the
                  // Tagalog word broke into "KAILANGA / N".
                  Positioned(
                    left: markX - 50,
                    top: 17,
                    child: SizedBox(
                      width: 100,
                      child: Text(
                        l.needed.toUpperCase(),
                        maxLines: 1,
                        softWrap: false,
                        textAlign: TextAlign.center,
                        style: AppFont.micro.copyWith(color: AppColor.ink3),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Ordered instructions on a numbered rail.
class StepRail extends StatelessWidget {
  final List<ActionStep> steps;
  final Color accent;

  const StepRail({super.key, required this.steps, required this.accent});

  @override
  Widget build(BuildContext context) {
    final Lang lang = L.of(context).lang;
    return Column(
      children: List<Widget>.generate(steps.length, (int i) {
        final ActionStep s = steps[i];
        final bool last = i == steps.length - 1;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Column(
                children: <Widget>[
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: AppFont.label.copyWith(color: AppColor.onDark),
                    ),
                  ),
                  if (!last)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: accent.withValues(alpha: 0.2),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: last ? 0 : Insets.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const SizedBox(height: 4),
                      Text(s.title(lang), style: AppFont.h3),
                      const SizedBox(height: 5),
                      Text(
                        s.why(lang),
                        style: AppFont.bodySm.copyWith(color: AppColor.ink2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

/// Signs, split by where they are seen.
class SignTabs extends StatefulWidget {
  final List<SignGroup> groups;
  final Color accent;

  const SignTabs({super.key, required this.groups, required this.accent});

  @override
  State<SignTabs> createState() => _SignTabsState();
}

class _SignTabsState extends State<SignTabs> {
  int _i = 0;

  @override
  void didUpdateWidget(SignTabs old) {
    super.didUpdateWidget(old);
    if (_i >= widget.groups.length) _i = 0;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.groups.isEmpty) return const SizedBox.shrink();
    final Lang lang = L.of(context).lang;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List<Widget>.generate(widget.groups.length, (int i) {
              final bool on = i == _i;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Material(
                  color: on ? AppColor.green900 : AppColor.surface,
                  borderRadius: BorderRadius.circular(Insets.rFull),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(Insets.rFull),
                    onTap: () => setState(() => _i = i),
                    child: Semantics(
                      selected: on,
                      button: true,
                      child: Container(
                        constraints: const BoxConstraints(
                          minHeight: Insets.tap - 4,
                        ),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(Insets.rFull),
                          border: Border.all(
                            color: on ? AppColor.green900 : AppColor.line,
                          ),
                        ),
                        child: Text(
                          widget.groups[i].where(lang),
                          style: AppFont.label.copyWith(
                            color: on ? AppColor.onDark : AppColor.ink2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: Insets.md),
        // Every group is laid out at once and the card takes the height of
        // the tallest, so switching tabs never moves anything below it. Only
        // the list inside crossfades. Before, the card resized on every tap
        // and the whole report underneath jumped with it.
        AppCard(
          child: Stack(
            children: List<Widget>.generate(widget.groups.length, (int i) {
              final bool on = i == _i;
              return IgnorePointer(
                ignoring: !on,
                child: ExcludeSemantics(
                  excluding: !on,
                  child: AnimatedOpacity(
                    opacity: on ? 1 : 0,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    child: _SignList(
                      items: widget.groups[i].items,
                      lang: lang,
                      accent: widget.accent,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

/// A block that carries one warning or obligation.
class Callout extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? body;
  final List<String> bullets;
  final Color ink;
  final Color fill;

  /// Crosses for prohibitions; plain dots for neutral lists, where a cross
  /// would read as "this is wrong".
  final bool crossBullets;

  const Callout({
    super.key,
    required this.icon,
    required this.title,
    required this.ink,
    required this.fill,
    this.body,
    this.bullets = const <String>[],
    this.crossBullets = true,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(Insets.card),
    decoration: BoxDecoration(
      color: fill,
      borderRadius: BorderRadius.circular(Insets.rMd),
      border: Border.all(color: ink.withValues(alpha: 0.3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(icon, size: 17, color: ink),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title.toUpperCase(),
                style: AppFont.micro.copyWith(color: ink),
              ),
            ),
          ],
        ),
        if (body != null) ...<Widget>[
          const SizedBox(height: 10),
          Text(body!, style: AppFont.bodySm),
        ],
        if (bullets.isNotEmpty) const SizedBox(height: 8),
        ...bullets.map(
          (String b) => Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (crossBullets)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(AppIcons.cross, size: 14, color: ink),
                  )
                else
                  Container(
                    margin: const EdgeInsets.only(top: 7, left: 4, right: 4),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: ink,
                      shape: BoxShape.circle,
                    ),
                  ),
                const SizedBox(width: 9),
                Expanded(child: Text(b, style: AppFont.bodySm)),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

/// A labelled 0–1 meter, used for the photo-quality figures.
class MiniMeter extends StatelessWidget {
  final String label;
  final double value;
  final String readout;

  const MiniMeter({
    super.key,
    required this.label,
    required this.value,
    required this.readout,
  });

  @override
  Widget build(BuildContext context) {
    final double v = value.clamp(0.0, 1.0);
    final Color ink = v >= 0.55
        ? AppColor.green700
        : v >= 0.3
        ? AppColor.caution
        : AppColor.danger;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  label,
                  style: AppFont.bodySm.copyWith(color: AppColor.ink2),
                ),
              ),
              Text(readout, style: AppFont.labelSm.copyWith(color: ink)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(Insets.rFull),
            child: LinearProgressIndicator(
              value: v,
              minHeight: 6,
              backgroundColor: AppColor.fill,
              valueColor: AlwaysStoppedAnimation<Color>(ink),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignList extends StatelessWidget {
  final List<Say> items;
  final Lang lang;
  final Color accent;

  const _SignList({
    required this.items,
    required this.lang,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: items
        .map(
          (Say s) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  margin: const EdgeInsets.only(top: 7, right: 11),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(child: Text(s(lang), style: AppFont.body)),
              ],
            ),
          ),
        )
        .toList(growable: false),
  );
}
