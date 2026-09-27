import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/icons.dart';
import '../core/strings.dart';
import '../core/tokens.dart';
import '../data/conditions.dart';
import '../data/scan_record.dart';
import '../data/scan_store.dart';
import 'detail_page.dart';
import 'widgets/common.dart';

enum _Window { week, month, all }

/// The scan log.
///
/// Built around the question a farmer actually brings here — "is the flock
/// getting better or worse, and which bird was that" — rather than "how many
/// scans have I done". The totals appear once, inside the health strip, not
/// again as stat tiles, a count pill and a footer as they did before.
///
/// Scans are grouped under the day they were taken, because "which bird was
/// that" is almost always answered by "the one on Tuesday". Exporting and
/// deleting live in Settings, with the other things done to the data as a
/// whole.
class RecordsPage extends StatefulWidget {
  final VoidCallback onScan;

  const RecordsPage({super.key, required this.onScan});

  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  final TextEditingController _search = TextEditingController();
  String _query = '';
  String _filter = 'all';
  _Window _window = _Window.month;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Duration get _windowSpan => switch (_window) {
    _Window.week => const Duration(days: 7),
    _Window.month => const Duration(days: 30),
    _Window.all => const Duration(days: 3650),
  };

  @override
  Widget build(BuildContext context) {
    final L l = L.of(context);
    final ScanStore store = context.watch<ScanStore>();
    final List<ScanRecord> all = store.items;

    if (all.isEmpty) {
      return _Empty(onScan: widget.onScan);
    }

    final List<ScanRecord> inWindow = store.within(_windowSpan);
    final Map<String, int> counts = <String, int>{
      'all': all.length,
      'healthy': all.where((ScanRecord r) => r.status == 'healthy').length,
      'inconclusive':
          all.where((ScanRecord r) => r.status == 'inconclusive').length,
      'disease': all.where((ScanRecord r) => r.status == 'disease').length,
    };

    final List<ScanRecord> shown = all.where((ScanRecord r) {
      if (_filter != 'all' && r.status != _filter) return false;
      if (_query.isEmpty) return true;
      final String q = _query.toLowerCase();
      final String number =
          '#${store.numberOf(r).toString().padLeft(3, '0')}';
      return r.coop.toLowerCase().contains(q) ||
          r.note.toLowerCase().contains(q) ||
          number.contains(q) ||
          conditionFor(r.conditionKey).name(l.lang).toLowerCase().contains(q);
    }).toList(growable: false);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Insets.screen,
        Insets.sm,
        Insets.screen,
        Insets.xxl,
      ),
      children: <Widget>[
        PageTitle(title: l.records, subtitle: l.recordsSub),
        _HealthStrip(
          window: _window,
          onWindow: (_Window w) => setState(() => _window = w),
          inWindow: inWindow,
          previous: _previousWindow(store),
        ),
        const SizedBox(height: Insets.md),
        TextField(
          controller: _search,
          onChanged: (String v) => setState(() => _query = v.trim()),
          decoration: InputDecoration(
            hintText: l.searchHint,
            isDense: true,
            prefixIcon: const Icon(AppIcons.search, size: 20),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    tooltip: l.close,
                    icon: const Icon(AppIcons.close, size: 18),
                    onPressed: () {
                      _search.clear();
                      setState(() => _query = '');
                    },
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: <Widget>[
              _FilterChip(
                label: l.all,
                count: counts['all']!,
                on: _filter == 'all',
                onTap: () => setState(() => _filter = 'all'),
              ),
              _FilterChip(
                label: l.healthy,
                count: counts['healthy']!,
                icon: statusIcon('healthy'),
                ink: AppColor.green700,
                on: _filter == 'healthy',
                onTap: () => setState(() => _filter = 'healthy'),
              ),
              _FilterChip(
                label: l.inconclusive,
                count: counts['inconclusive']!,
                icon: statusIcon('inconclusive'),
                ink: AppColor.caution,
                on: _filter == 'inconclusive',
                onTap: () => setState(() => _filter = 'inconclusive'),
              ),
              _FilterChip(
                label: l.diseased,
                count: counts['disease']!,
                icon: statusIcon('disease'),
                ink: AppColor.danger,
                on: _filter == 'disease',
                onTap: () => setState(() => _filter = 'disease'),
              ),
            ],
          ),
        ),
        const SizedBox(height: Insets.lg),
        if (shown.isEmpty)
          AppCard(
            padding: const EdgeInsets.symmetric(
              horizontal: Insets.card,
              vertical: Insets.lg,
            ),
            child: Column(
              children: <Widget>[
                const Icon(AppIcons.noResults,
                    size: 32, color: AppColor.ink3),
                const SizedBox(height: 10),
                Text(
                  l.noMatches,
                  style: AppFont.body.copyWith(color: AppColor.ink2),
                ),
              ],
            ),
          )
        else
          ..._grouped(context, l, store, shown),
      ],
    );
  }

  /// The rows, with a day heading wherever the day changes. The store keeps
  /// records newest first, so one pass is enough.
  List<Widget> _grouped(
    BuildContext context,
    L l,
    ScanStore store,
    List<ScanRecord> shown,
  ) {
    final List<Widget> out = <Widget>[];
    DateTime? day;
    for (final ScanRecord r in shown) {
      final DateTime d = DateUtils.dateOnly(r.at);
      if (day == null || d != day) {
        day = d;
        out.add(_DayHeading(label: _dayLabel(l, d), first: out.isEmpty));
      }
      out.add(
        _Row(
          record: r,
          number: store.numberOf(r),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => DetailPage(recordId: r.id),
            ),
          ),
        ),
      );
    }
    return out;
  }

  String _dayLabel(L l, DateTime d) {
    final DateTime today = DateUtils.dateOnly(DateTime.now());
    if (d == today) return l.today;
    if (d == today.subtract(const Duration(days: 1))) return l.yesterday;
    return DateFormat(d.year == today.year ? 'EEE, d MMM' : 'd MMM y')
        .format(d);
  }

  /// The equivalent window immediately before this one, for the trend line.
  List<ScanRecord> _previousWindow(ScanStore store) {
    if (_window == _Window.all) return const <ScanRecord>[];
    final DateTime now = DateTime.now();
    final DateTime start = now.subtract(_windowSpan * 2);
    final DateTime end = now.subtract(_windowSpan);
    return store.items
        .where((ScanRecord r) => r.at.isAfter(start) && r.at.isBefore(end))
        .toList(growable: false);
  }
}

/// Proportions, plus whether they are moving in the right direction.
class _HealthStrip extends StatelessWidget {
  final _Window window;
  final ValueChanged<_Window> onWindow;
  final List<ScanRecord> inWindow;
  final List<ScanRecord> previous;

  const _HealthStrip({
    required this.window,
    required this.onWindow,
    required this.inWindow,
    required this.previous,
  });

  @override
  Widget build(BuildContext context) {
    final L l = L.of(context);
    final int healthy =
        inWindow.where((ScanRecord r) => r.status == 'healthy').length;
    final int unsure =
        inWindow.where((ScanRecord r) => r.status == 'inconclusive').length;
    final int sick =
        inWindow.where((ScanRecord r) => r.status == 'disease').length;
    final int total = inWindow.length;

    final double? now = ScanStore.healthyShare(inWindow);
    final double? before = ScanStore.healthyShare(previous);

    String trend;
    IconData trendIcon;
    Color trendInk;
    Color trendFill;
    if (now == null || before == null) {
      trend = l.notEnoughData;
      trendIcon = AppIcons.noTrend;
      trendInk = AppColor.ink3;
      trendFill = AppColor.fill;
    } else if (now - before > 0.08) {
      trend = l.trendBetter;
      trendIcon = AppIcons.trendUp;
      trendInk = AppColor.green700;
      trendFill = AppColor.mintSoft;
    } else if (before - now > 0.08) {
      trend = l.trendWorse;
      trendIcon = AppIcons.trendDown;
      trendInk = AppColor.danger;
      trendFill = AppColor.dangerSoft;
    } else {
      trend = l.trendSame;
      trendIcon = AppIcons.trendFlat;
      trendInk = AppColor.ink3;
      trendFill = AppColor.fill;
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: Text(l.flockHealth, style: AppFont.h3)),
              Text(
                l.countScans(total),
                style: AppFont.labelSm.copyWith(color: AppColor.ink3),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Segmented<_Window>(
            value: window,
            onChanged: onWindow,
            options: <(_Window, String)>[
              (_Window.week, l.last7),
              (_Window.month, l.last30),
              (_Window.all, l.allTime),
            ],
          ),
          const SizedBox(height: Insets.md),
          if (total == 0)
            Text(
              l.notEnoughData,
              style: AppFont.bodySm.copyWith(color: AppColor.ink3),
            )
          else ...<Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(Insets.rFull),
              child: SizedBox(
                height: 10,
                // Stretch, or the childless ColoredBoxes collapse to zero
                // height and the bar never shows — which it didn't, before.
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (healthy > 0)
                      Expanded(
                        flex: healthy,
                        child: const ColoredBox(color: AppColor.green700),
                      ),
                    if (healthy > 0 && (unsure > 0 || sick > 0))
                      const SizedBox(width: 2),
                    if (unsure > 0)
                      Expanded(
                        flex: unsure,
                        child: const ColoredBox(color: AppColor.caution),
                      ),
                    if (unsure > 0 && sick > 0) const SizedBox(width: 2),
                    if (sick > 0)
                      Expanded(
                        flex: sick,
                        child: const ColoredBox(color: AppColor.danger),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                _Legend(
                  ink: AppColor.green700,
                  label: l.healthy,
                  value: healthy,
                  total: total,
                ),
                _Legend(
                  ink: AppColor.caution,
                  label: l.inconclusive,
                  value: unsure,
                  total: total,
                ),
                _Legend(
                  ink: AppColor.danger,
                  label: l.diseased,
                  value: sick,
                  total: total,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: trendFill,
                borderRadius: BorderRadius.circular(Insets.rSm),
              ),
              child: Row(
                children: <Widget>[
                  Icon(trendIcon, size: 16, color: trendInk),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      trend,
                      style: AppFont.labelSm.copyWith(color: trendInk),
                    ),
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

class _Legend extends StatelessWidget {
  final Color ink;
  final String label;
  final int value;
  final int total;

  const _Legend({
    required this.ink,
    required this.label,
    required this.value,
    required this.total,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: ink, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text('$value', style: AppFont.h3),
            const SizedBox(width: 5),
            Text(
              '${total == 0 ? 0 : (value * 100 / total).round()}%',
              style: AppFont.micro.copyWith(color: AppColor.ink3),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppFont.labelSm.copyWith(color: AppColor.ink2),
        ),
      ],
    ),
  );
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool on;
  final IconData? icon;
  final Color? ink;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.on,
    required this.onTap,
    this.icon,
    this.ink,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: Material(
      color: on ? AppColor.green900 : AppColor.surface,
      borderRadius: BorderRadius.circular(Insets.rFull),
      child: InkWell(
        borderRadius: BorderRadius.circular(Insets.rFull),
        onTap: onTap,
        child: Semantics(
          selected: on,
          button: true,
          child: Container(
            constraints: const BoxConstraints(minHeight: Insets.tap - 4),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Insets.rFull),
              border: Border.all(
                color: on ? AppColor.green900 : AppColor.line,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  Icon(
                    icon,
                    size: 15,
                    color: on ? AppColor.onDark : ink,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: AppFont.label.copyWith(
                    color: on ? AppColor.onDark : AppColor.ink,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  '$count',
                  style: AppFont.labelSm.copyWith(
                    color: on ? AppColor.mint : AppColor.ink3,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _DayHeading extends StatelessWidget {
  final String label;
  final bool first;

  const _DayHeading({required this.label, required this.first});

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: first ? 0 : 14, bottom: 8, left: 2),
    child: Semantics(
      header: true,
      child: Text(
        label.toUpperCase(),
        style: AppFont.micro.copyWith(color: AppColor.ink3),
      ),
    ),
  );
}

class _Row extends StatelessWidget {
  final ScanRecord record;
  final int number;
  final VoidCallback onTap;

  const _Row({
    required this.record,
    required this.number,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final L l = L.of(context);
    final Condition c = conditionFor(record.conditionKey);
    final Color ink = statusInk(record.status);
    final String tag = '#${number.toString().padLeft(3, '0')}';
    final String coop = record.coop.trim();
    final String note = record.note.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(Insets.rMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(Insets.rMd),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 76),
            padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Insets.rMd),
              border: Border.all(color: AppColor.line),
            ),
            child: Row(
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(Insets.rSm),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: record.imagePath.isEmpty
                        ? const _Thumb(icon: AppIcons.image)
                        : Image.file(
                            File(record.imagePath),
                            fit: BoxFit.cover,
                            // Decode at thumbnail size, not camera size: a
                            // long log of full-resolution photos is what makes
                            // a cheap phone stutter on scroll.
                            cacheWidth: 168,
                            errorBuilder: (_, _, _) => const _Thumb(
                              icon: AppIcons.imageBroken,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // What was found leads; where and when is the subtitle.
                      Row(
                        children: <Widget>[
                          Icon(statusIcon(record.status),
                              size: 16, color: ink),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              c.name(l.lang),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppFont.h3.copyWith(color: ink),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // The coop name gives way first; the number and the time
                      // always stay visible.
                      Row(
                        children: <Widget>[
                          if (coop.isNotEmpty) ...<Widget>[
                            Flexible(
                              child: Text(
                                coop,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppFont.bodySm
                                    .copyWith(color: AppColor.ink),
                              ),
                            ),
                            Text(
                              '  ·  ',
                              style: AppFont.bodySm
                                  .copyWith(color: AppColor.ink3),
                            ),
                          ],
                          Text(
                            '$tag  ·  '
                            '${DateFormat('h:mm a').format(record.at)}',
                            maxLines: 1,
                            style:
                                AppFont.bodySm.copyWith(color: AppColor.ink3),
                          ),
                        ],
                      ),
                      if (note.isNotEmpty)
                        Text(
                          note,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFont.bodySm.copyWith(color: AppColor.ink3),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(AppIcons.chevron, size: 18, color: AppColor.ink3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final IconData icon;

  const _Thumb({required this.icon});

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColor.fill,
    child: Icon(icon, size: 22, color: AppColor.ink3),
  );
}

/// First run. Says what the page is for, once, with the one button that
/// starts filling it.
class _Empty extends StatelessWidget {
  final VoidCallback onScan;

  const _Empty({required this.onScan});

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
        PageTitle(title: l.records, subtitle: l.recordsSub),
        const SizedBox(height: Insets.lg),
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              color: AppColor.mintSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              AppIcons.emptyLog,
              size: 44,
              color: AppColor.green700,
            ),
          ),
        ),
        const SizedBox(height: Insets.lg),
        Text(l.noRecordsYet, textAlign: TextAlign.center, style: AppFont.h2),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Insets.sm),
          child: Text(
            l.noRecordsBody,
            textAlign: TextAlign.center,
            style: AppFont.body.copyWith(color: AppColor.ink2),
          ),
        ),
        const SizedBox(height: Insets.lg),
        ElevatedButton.icon(
          onPressed: onScan,
          icon: const Icon(AppIcons.scan, size: 20),
          label: Text(l.startScanning),
        ),
        const SizedBox(height: Insets.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(AppIcons.offline, size: 15, color: AppColor.ink3),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                l.savedOffline,
                style: AppFont.labelSm.copyWith(color: AppColor.ink3),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
