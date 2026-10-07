import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
/// Opens on the one question a farmer brings here — "do I need to do
/// something?" — answered in a sentence, with the latest sick result one tap
/// away. The counts sit under it, and tapping a count filters the list, so the
/// card is also the filter: the separate row of filter chips repeated the same
/// numbers and is gone.
///
/// The period switch governs the whole page, list included, so "2 sick" in the
/// card and the list underneath always agree.
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

  /// Scans picked for deletion. Long-pressing a row starts picking; while
  /// anything is picked, a tap toggles a row instead of opening it.
  final Set<int> _selected = <int>{};
  bool get _selecting => _selected.isNotEmpty;

  void _toggle(ScanRecord r) => setState(() {
    if (!_selected.remove(r.id)) _selected.add(r.id);
  });

  void _startSelecting(ScanRecord r) {
    HapticFeedback.selectionClick();
    setState(() => _selected.add(r.id));
  }

  Future<void> _deleteSelected(ScanStore store, List<ScanRecord> shown) async {
    final L l = L.of(context);
    final int n = _selected.length;
    final bool everything = n == store.items.length;
    final bool yes = await confirmDestructive(
      context,
      title: everything ? l.clearRecordsQ : l.deleteSelectedQ(n),
      body: everything ? l.clearRecordsBody : l.deleteSelectedBody,
      action: l.delete,
    );
    if (!yes || !mounted) return;
    final Set<int> ids = <int>{..._selected};
    setState(_selected.clear);
    await store.removeMany(ids);
    if (mounted) showToast(context, l.deletedCount(ids.length));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Duration get _windowSpan => switch (_window) {
    _Window.week => const Duration(days: 7),
    _Window.month => const Duration(days: 30),
    _Window.all => const Duration(days: 36500),
  };

  int? get _windowDays => switch (_window) {
    _Window.week => 7,
    _Window.month => 30,
    _Window.all => null,
  };

  /// Tapping the active count again clears it, so the same control both sets
  /// and undoes the filter.
  void _toggleFilter(String status) =>
      setState(() => _filter = _filter == status ? 'all' : status);

  void _open(ScanRecord r) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => DetailPage(recordId: r.id)));

  @override
  Widget build(BuildContext context) {
    final L l = L.of(context);
    final ScanStore store = context.watch<ScanStore>();
    final List<ScanRecord> all = store.items;

    if (all.isEmpty) {
      return _Empty(onScan: widget.onScan);
    }

    final List<ScanRecord> inWindow = store.within(_windowSpan);

    final List<ScanRecord> shown = inWindow
        .where((ScanRecord r) {
          if (_filter != 'all' && r.status != _filter) return false;
          if (_query.isEmpty) return true;
          final String q = _query.toLowerCase();
          final String number =
              '#${store.numberOf(r).toString().padLeft(3, '0')}';
          return r.coop.toLowerCase().contains(q) ||
              r.note.toLowerCase().contains(q) ||
              number.contains(q) ||
              conditionFor(
                r.conditionKey,
              ).name(l.lang).toLowerCase().contains(q);
        })
        .toList(growable: false);

    final String? filterLabel = switch (_filter) {
      'healthy' => l.healthy,
      'disease' => l.diseased,
      'inconclusive' => l.inconclusive,
      _ => null,
    };

    // Scans that disappeared (filters changed, or deleted elsewhere) drop
    // out of the selection.
    _selected.removeWhere((int id) => !all.any((ScanRecord r) => r.id == id));
    final bool allShownPicked =
        shown.isNotEmpty &&
        shown.every((ScanRecord r) => _selected.contains(r.id));

    return PopScope(
      canPop: !_selecting,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (!didPop && _selecting) setState(_selected.clear);
      },
      child: Column(
        children: <Widget>[
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: !_selecting
                ? const SizedBox(width: double.infinity)
                : _SelectionBar(
                    count: _selected.length,
                    allPicked: allShownPicked,
                    onCancel: () => setState(_selected.clear),
                    onSelectAll: () => setState(() {
                      if (allShownPicked) {
                        _selected.clear();
                      } else {
                        _selected.addAll(shown.map((ScanRecord r) => r.id));
                      }
                    }),
                    onDelete: () => _deleteSelected(store, shown),
                  ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                Insets.screen,
                Insets.sm,
                Insets.screen,
                Insets.xxl,
              ),
              children: <Widget>[
                PageTitle(title: l.records, subtitle: l.recordsSub),
                _HealthCard(
                  window: _window,
                  days: _windowDays,
                  onWindow: (_Window w) => setState(() => _window = w),
                  inWindow: inWindow,
                  previous: _previousWindow(store),
                  lastScan: all.first.at,
                  filter: _filter,
                  onFilter: _toggleFilter,
                  onOpen: _open,
                  onScan: widget.onScan,
                  dayLabel: (DateTime d) => _dayLabel(l, d),
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
                // A visible, one-tap way back out of a filter set from the card.
                if (filterLabel != null) ...<Widget>[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: InputChip(
                      avatar: Icon(
                        statusIcon(_filter),
                        size: 16,
                        color: statusInk(_filter),
                      ),
                      label: Text('${l.showing}: $filterLabel'),
                      labelStyle: AppFont.label.copyWith(color: AppColor.ink),
                      deleteIcon: const Icon(AppIcons.close, size: 16),
                      deleteButtonTooltipMessage: l.showAll,
                      onDeleted: () => setState(() => _filter = 'all'),
                      onPressed: () => setState(() => _filter = 'all'),
                    ),
                  ),
                ],
                // How to delete, said once, where the list starts.
                if (shown.isNotEmpty && !_selecting) ...<Widget>[
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      const Icon(AppIcons.info, size: 15, color: AppColor.ink3),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l.longPressHint,
                          style: AppFont.labelSm.copyWith(color: AppColor.ink3),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: Insets.lg),
                if (shown.isEmpty)
                  AppCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Insets.card,
                      vertical: Insets.lg,
                    ),
                    child: Column(
                      children: <Widget>[
                        const Icon(
                          AppIcons.noResults,
                          size: 32,
                          color: AppColor.ink3,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          l.noMatches,
                          style: AppFont.body.copyWith(color: AppColor.ink2),
                        ),
                      ],
                    ),
                  )
                else
                  ..._grouped(l, store, shown),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The rows, with a day heading wherever the day changes. The store keeps
  /// records newest first, so one pass is enough.
  List<Widget> _grouped(L l, ScanStore store, List<ScanRecord> shown) {
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
          selected: _selected.contains(r.id),
          onTap: () => _selecting ? _toggle(r) : _open(r),
          onLongPress: () => _selecting ? _toggle(r) : _startSelecting(r),
        ),
      );
    }
    return out;
  }

  String _dayLabel(L l, DateTime d) {
    final DateTime today = DateUtils.dateOnly(DateTime.now());
    final DateTime day = DateUtils.dateOnly(d);
    if (day == today) return l.today;
    if (day == today.subtract(const Duration(days: 1))) return l.yesterday;
    return DateFormat(
      day.year == today.year ? 'EEE, d MMM' : 'd MMM y',
    ).format(day);
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

/// The answer to "do I need to do something?", then the evidence.
///
///   1. One sentence, coloured by what it says.
///   2. The latest sick result, one tap from its "what to do" steps.
///   3. Healthy vs sick — counts, not percentages; with a handful of scans a
///      percentage claims more precision than there is. Each count is also
///      the filter for the list below.
///   4. Retakes on their own line. They are about the photo, not the bird, so
///      they are kept out of the health bar.
///   5. The trend, only once there is enough to compare.
class _HealthCard extends StatelessWidget {
  final _Window window;
  final int? days;
  final ValueChanged<_Window> onWindow;
  final List<ScanRecord> inWindow;
  final List<ScanRecord> previous;
  final DateTime lastScan;
  final String filter;
  final ValueChanged<String> onFilter;
  final ValueChanged<ScanRecord> onOpen;
  final VoidCallback onScan;
  final String Function(DateTime) dayLabel;

  const _HealthCard({
    required this.window,
    required this.days,
    required this.onWindow,
    required this.inWindow,
    required this.previous,
    required this.lastScan,
    required this.filter,
    required this.onFilter,
    required this.onOpen,
    required this.onScan,
    required this.dayLabel,
  });

  /// A week without a scan is long enough for a problem to take hold.
  static const int _staleDays = 7;

  @override
  Widget build(BuildContext context) {
    final L l = L.of(context);
    final int healthy = inWindow
        .where((ScanRecord r) => r.status == 'healthy')
        .length;
    final int retakes = inWindow
        .where((ScanRecord r) => r.status == 'inconclusive')
        .length;
    final List<ScanRecord> sickList = inWindow
        .where((ScanRecord r) => r.status == 'disease')
        .toList(growable: false);
    final int sick = sickList.length;
    final int sinceLast = DateTime.now().difference(lastScan).inDays;

    // ── 1. the headline ──────────────────────────────────────────────────
    final (String headline, IconData icon, Color ink, Color fill) = sick > 0
        ? (
            l.sickFound(sick, days),
            AppIcons.serious,
            AppColor.danger,
            AppColor.dangerSoft,
          )
        : healthy > 0
        ? (
            l.noSickFound(days),
            AppIcons.healthy,
            AppColor.green700,
            AppColor.mintSoft,
          )
        : retakes > 0
        ? (
            l.noClearResults,
            AppIcons.unsure,
            AppColor.caution,
            AppColor.cautionSoft,
          )
        : (l.noScansIn(days), AppIcons.scan, AppColor.ink2, AppColor.fill);

    // ── 5. the trend, only when it has something to say ───────────────────
    final double? now = ScanStore.healthyShare(inWindow);
    final double? before = ScanStore.healthyShare(previous);
    (String, IconData, Color)? trend;
    if (now != null && before != null) {
      trend = now - before > 0.08
          ? (l.trendBetter, AppIcons.trendUp, AppColor.green700)
          : before - now > 0.08
          ? (l.trendWorse, AppIcons.trendDown, AppColor.danger)
          : (l.trendSame, AppIcons.trendFlat, AppColor.ink3);
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
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

          // 1. headline
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(Insets.rMd),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(icon, size: 22, color: ink),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    headline,
                    style: AppFont.h3.copyWith(color: ink, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),

          // 2. the latest sick result, straight to its steps
          if (sickList.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            _LatestSick(
              record: sickList.first,
              when: dayLabel(sickList.first.at),
              onTap: () => onOpen(sickList.first),
            ),
          ],

          // 3. healthy vs sick, as counts that double as the filter
          if (healthy + sick > 0) ...<Widget>[
            const SizedBox(height: Insets.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(Insets.rFull),
              child: SizedBox(
                height: 8,
                // Stretch, or the childless ColoredBoxes collapse to zero
                // height and the bar never shows.
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (healthy > 0)
                      Expanded(
                        flex: healthy,
                        child: const ColoredBox(color: AppColor.green700),
                      ),
                    if (healthy > 0 && sick > 0) const SizedBox(width: 2),
                    if (sick > 0)
                      Expanded(
                        flex: sick,
                        child: const ColoredBox(color: AppColor.danger),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: _Count(
                    status: 'healthy',
                    value: healthy,
                    label: l.healthy,
                    on: filter == 'healthy',
                    onTap: () => onFilter('healthy'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Count(
                    status: 'disease',
                    value: sick,
                    label: l.diseased,
                    on: filter == 'disease',
                    onTap: () => onFilter('disease'),
                  ),
                ),
              ],
            ),
          ],

          // 4. retakes, kept apart from health
          if (retakes > 0 && healthy + sick > 0) ...<Widget>[
            const SizedBox(height: 8),
            _LinkRow(
              icon: AppIcons.unsure,
              ink: AppColor.caution,
              text: l.needRetake(retakes),
              on: filter == 'inconclusive',
              onTap: () => onFilter('inconclusive'),
            ),
          ],

          // 5. trend
          if (trend != null) ...<Widget>[
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                const SizedBox(width: 4),
                Icon(trend.$2, size: 16, color: trend.$3),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    trend.$1,
                    style: AppFont.label.copyWith(color: trend.$3),
                  ),
                ),
              ],
            ),
          ],

          // A nudge when the farm has gone quiet, whatever the period shows.
          if (sinceLast >= _staleDays) ...<Widget>[
            const SizedBox(height: 8),
            _LinkRow(
              icon: AppIcons.thisWeek,
              ink: AppColor.ink2,
              text: '${l.lastScanAgo(sinceLast)} · ${l.scanNow}',
              onTap: onScan,
            ),
          ],
        ],
      ),
    );
  }
}

/// The most recent sick result, as a row that opens its report.
class _LatestSick extends StatelessWidget {
  final ScanRecord record;
  final String when;
  final VoidCallback onTap;

  const _LatestSick({
    required this.record,
    required this.when,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final L l = L.of(context);
    final String where = record.coop.trim();
    return Material(
      color: AppColor.surface,
      borderRadius: BorderRadius.circular(Insets.rMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(Insets.rMd),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: Insets.tap + 8),
          padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Insets.rMd),
            border: Border.all(color: AppColor.line),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l.latest.toUpperCase(),
                      style: AppFont.micro.copyWith(color: AppColor.ink3),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      conditionFor(record.conditionKey).name(l.lang),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFont.label.copyWith(
                        color: AppColor.danger,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      where.isEmpty ? when : '$where  ·  $when',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFont.bodySm.copyWith(color: AppColor.ink2),
                    ),
                  ],
                ),
              ),
              const Icon(AppIcons.chevron, size: 18, color: AppColor.ink3),
            ],
          ),
        ),
      ),
    );
  }
}

/// One count in the card. Tapping it filters the list to those scans.
class _Count extends StatelessWidget {
  final String status;
  final int value;
  final String label;
  final bool on;
  final VoidCallback onTap;

  const _Count({
    required this.status,
    required this.value,
    required this.label,
    required this.on,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color ink = statusInk(status);
    return Semantics(
      button: true,
      selected: on,
      label: '$value $label',
      excludeSemantics: true,
      child: Material(
        color: on ? AppColor.fill : Colors.transparent,
        borderRadius: BorderRadius.circular(Insets.rSm),
        child: InkWell(
          borderRadius: BorderRadius.circular(Insets.rSm),
          onTap: value == 0 ? null : onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: Insets.tap),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Insets.rSm),
              border: Border.all(
                color: on ? AppColor.ink3 : Colors.transparent,
              ),
            ),
            child: Row(
              children: <Widget>[
                Icon(statusIcon(status), size: 16, color: ink),
                const SizedBox(width: 7),
                Text(
                  '$value',
                  style: AppFont.h2.copyWith(
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFont.label.copyWith(color: AppColor.ink2),
                  ),
                ),
                if (value > 0)
                  const Icon(AppIcons.chevron, size: 14, color: AppColor.ink3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A small tappable line inside the card: the retake count, the scan nudge.
class _LinkRow extends StatelessWidget {
  final IconData icon;
  final Color ink;
  final String text;
  final VoidCallback onTap;
  final bool on;

  const _LinkRow({
    required this.icon,
    required this.ink,
    required this.text,
    required this.onTap,
    this.on = false,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: on ? AppColor.fill : Colors.transparent,
    borderRadius: BorderRadius.circular(Insets.rSm),
    child: InkWell(
      borderRadius: BorderRadius.circular(Insets.rSm),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 40),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 16, color: ink),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: AppFont.label.copyWith(color: AppColor.ink2),
              ),
            ),
            const Icon(AppIcons.chevron, size: 14, color: AppColor.ink3),
          ],
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
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _Row({
    required this.record,
    required this.number,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
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
        color: selected ? AppColor.mintSoft : AppColor.surface,
        borderRadius: BorderRadius.circular(Insets.rMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(Insets.rMd),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Container(
            constraints: const BoxConstraints(minHeight: 76),
            padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Insets.rMd),
              border: Border.all(
                color: selected ? AppColor.green700 : AppColor.line,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: <Widget>[
                Stack(
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
                                errorBuilder: (_, _, _) =>
                                    const _Thumb(icon: AppIcons.imageBroken),
                              ),
                      ),
                    ),
                    // The tick: selection shown by shape, not only by colour.
                    if (selected)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColor.green900.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(Insets.rSm),
                          ),
                          child: const Icon(
                            AppIcons.check,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                  ],
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
                          Icon(statusIcon(record.status), size: 16, color: ink),
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
                                style: AppFont.bodySm.copyWith(
                                  color: AppColor.ink,
                                ),
                              ),
                            ),
                            Text(
                              '  ·  ',
                              style: AppFont.bodySm.copyWith(
                                color: AppColor.ink3,
                              ),
                            ),
                          ],
                          Text(
                            '$tag  ·  '
                            '${DateFormat('h:mm a').format(record.at)}',
                            maxLines: 1,
                            style: AppFont.bodySm.copyWith(
                              color: AppColor.ink3,
                            ),
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

/// Shown while scans are picked: how many, select-all, delete, cancel.
class _SelectionBar extends StatelessWidget {
  final int count;
  final bool allPicked;
  final VoidCallback onCancel;
  final VoidCallback onSelectAll;
  final VoidCallback onDelete;

  const _SelectionBar({
    required this.count,
    required this.allPicked,
    required this.onCancel,
    required this.onSelectAll,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final L l = L.of(context);
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColor.mintSoft,
        border: Border(bottom: BorderSide(color: AppColor.mintLine)),
      ),
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
      child: Row(
        children: <Widget>[
          IconButton(
            tooltip: l.cancel,
            icon: const Icon(AppIcons.close),
            onPressed: onCancel,
          ),
          Expanded(
            child: Text(
              l.selectedCount(count),
              style: AppFont.h3.copyWith(color: AppColor.green900),
            ),
          ),
          TextButton(
            onPressed: onSelectAll,
            child: Text(allPicked ? l.selectNone : l.selectAll),
          ),
          IconButton(
            tooltip: l.delete,
            icon: const Icon(AppIcons.delete, color: AppColor.danger),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
