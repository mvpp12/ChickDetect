import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/icons.dart';
import '../core/strings.dart';
import '../core/tokens.dart';
import '../data/care.dart';
import '../data/conditions.dart';
import '../data/scan_record.dart';
import '../data/scan_store.dart';
import '../ml/classifier.dart';
import '../ml/colour_check.dart';
import '../ml/decision.dart';
import 'widgets/common.dart';
import 'widgets/labels_form.dart';
import 'widgets/report.dart';
import 'widgets/vet_contacts.dart';

enum _Tab { overview, analysis, care, vet }

/// The full record of one scan, in tabs.
///
/// It used to be one long page — verdict, facts, the law, signs, two sets of
/// steps, warnings, scores and photo quality, top to bottom. The tabs follow
/// the order a worried farmer asks the questions in: what did it find
/// (Overview) → why (AI Analysis) → what do I see (Symptoms) → what do I do
/// (Recommendations) → when do I call (Vet Care), with the photo last.
///
/// Reads the record from the store by id rather than taking a copy, so edits
/// made here — renaming a coop, ticking symptoms, deleting — show everywhere
/// at once.
class DetailPage extends StatelessWidget {
  final int recordId;

  const DetailPage({super.key, required this.recordId});

  @override
  Widget build(BuildContext context) {
    final L l = L.of(context);
    final ScanStore store = context.watch<ScanStore>();

    ScanRecord? record;
    for (final ScanRecord r in store.items) {
      if (r.id == recordId) record = r;
    }

    if (record == null) {
      // The scan was deleted while this page was open.
      return Scaffold(
        appBar: AppBar(title: Text(l.records)),
        body: Center(
          child: Text(
            l.noMatches,
            style: AppFont.body.copyWith(color: AppColor.ink3),
          ),
        ),
      );
    }

    final ScanRecord r = record;
    final Condition condition = conditionFor(r.conditionKey);
    final int number = store.numberOf(r);

    final List<_Tab> tabs = <_Tab>[
      _Tab.overview,
      _Tab.analysis,
      _Tab.care,
      _Tab.vet,
    ];

    (String, IconData) spec(_Tab t) => switch (t) {
      _Tab.overview => (l.tabOverview, AppIcons.tabOverview),
      _Tab.analysis => (l.tabAnalysis, AppIcons.scores),
      _Tab.care => (l.tabCare, AppIcons.tabCare),
      _Tab.vet => (l.tabVet, AppIcons.tabVet),
    };

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        backgroundColor: AppColor.bg,
        appBar: AppBar(
          title: Text('#${number.toString().padLeft(3, '0')}'),
          actions: <Widget>[
            IconButton(
              tooltip: l.editLabels,
              icon: const Icon(AppIcons.edit),
              onPressed: () => _editLabels(context, r),
            ),
            IconButton(
              tooltip: l.delete,
              icon: const Icon(AppIcons.delete),
              onPressed: () => _confirmDelete(context, store, r),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: Builder(
          builder: (BuildContext inner) {
            void jump(_Tab to) {
              final int i = tabs.indexOf(to);
              if (i >= 0) DefaultTabController.of(inner).animateTo(i);
            }

            return Column(
              children: <Widget>[
                _Summary(record: r, condition: condition),
                Container(
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColor.line)),
                  ),
                  // Fixed, not scrollable: every tab is on screen at once. The
                  // scrolling bar hid everything after the third tab on a phone,
                  // and nobody scrolls a tab bar they do not know is longer.
                  child: TabBar(
                    labelPadding: EdgeInsets.zero,
                    labelColor: AppColor.green900,
                    unselectedLabelColor: AppColor.ink3,
                    indicatorColor: AppColor.green700,
                    indicatorWeight: 3,
                    indicatorSize: TabBarIndicatorSize.label,
                    dividerColor: Colors.transparent,
                    tabs: tabs
                        .map((_Tab t) {
                          final (String label, IconData icon) = spec(t);
                          return Tab(
                            height: 58,
                            iconMargin: const EdgeInsets.only(bottom: 3),
                            icon: Icon(icon, size: 20),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  label,
                                  maxLines: 1,
                                  style: AppFont.labelSm.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          );
                        })
                        .toList(growable: false),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: tabs
                        .map((_Tab t) {
                          return switch (t) {
                            _Tab.overview => _OverviewTab(
                              record: r,
                              condition: condition,
                              onEdit: () => _editLabels(context, r),
                              jumpTo: jump,
                              hasTab: tabs.contains,
                            ),
                            _Tab.analysis => _AnalysisTab(record: r),
                            _Tab.care => _CareTab(condition: condition),
                            _Tab.vet => _VetTab(condition: condition),
                          };
                        })
                        .toList(growable: false),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _editLabels(BuildContext context, ScanRecord r) async {
    final L l = L.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext ctx) => SheetFrame(
        children: <Widget>[
          Text(l.editLabels, style: AppFont.h2),
          const SizedBox(height: Insets.md),
          ScanLabelsForm(record: r),
          const SizedBox(height: Insets.lg),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l.done),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ScanStore store,
    ScanRecord r,
  ) async {
    final L l = L.of(context);
    final bool yes = await confirmDestructive(
      context,
      title: l.deleteScanQ,
      body: l.deleteScanBody,
      action: l.delete,
    );
    if (!yes || !context.mounted) return;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    await store.remove(r.id);
    if (!context.mounted) return;
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l.scanDeleted)));
  }
}

bool _hasPhoto(ScanRecord r) => !kIsWeb && r.imagePath.isNotEmpty;

// ─────────────────────────────────────────────────────────────────────────
// Summary strip — always visible above the tabs
// ─────────────────────────────────────────────────────────────────────────

class _Summary extends StatelessWidget {
  final ScanRecord record;
  final Condition condition;

  const _Summary({required this.record, required this.condition});

  @override
  Widget build(BuildContext context) {
    final L l = L.of(context);
    final Color ink = severityInk(condition);
    final String coop = record.coop.trim();
    return Container(
      color: severityFill(condition),
      padding: const EdgeInsets.fromLTRB(Insets.screen, 12, Insets.screen, 12),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(severityIcon(condition), size: 18, color: ink),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        condition.name(l.lang),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFont.h2.copyWith(color: ink),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  <String>[
                    if (coop.isNotEmpty) coop,
                    DateFormat('d MMM y · h:mm a').format(record.at),
                  ].join('  ·  '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFont.bodySm.copyWith(color: AppColor.ink2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Every tab scrolls the same way and keeps its place when you switch away.
class _TabList extends StatefulWidget {
  final List<Widget> children;

  const _TabList({required this.children});

  @override
  State<_TabList> createState() => _TabListState();
}

class _TabListState extends State<_TabList> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Insets.screen,
        Insets.md,
        Insets.screen,
        Insets.xxl,
      ),
      children: widget.children,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Overview
// ─────────────────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final ScanRecord record;
  final Condition condition;
  final VoidCallback onEdit;
  final ValueChanged<_Tab> jumpTo;
  final bool Function(_Tab) hasTab;

  const _OverviewTab({
    required this.record,
    required this.condition,
    required this.onEdit,
    required this.jumpTo,
    required this.hasTab,
  });

  @override
  Widget build(BuildContext context) {
    final L l = L.of(context);
    final Lang lang = l.lang;
    final String coop = record.coop.trim();
    final String note = record.note.trim();

    return _TabList(
      children: <Widget>[
        // The photo that was scanned, at the top — tap for full screen.
        if (_hasPhoto(record)) ...<Widget>[
          _ScanPhoto(file: File(record.imagePath)),
          const SizedBox(height: Insets.md),
        ],
        VerdictCard(
          condition: condition,
          confidence: record.photoRejected ? null : record.confidence,
          rawLabel: record.label.isEmpty ? null : record.label,
          showName: false,
        ),
        const SizedBox(height: Insets.md),

        // Facts about this scan
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: Insets.card),
          child: Column(
            children: <Widget>[
              _InfoRow(
                icon: AppIcons.thisWeek,
                label: l.scannedOn,
                child: Text(
                  DateFormat('d MMMM y · h:mm a').format(record.at),
                  style: AppFont.label,
                ),
              ),
              const Divider(),
              _InfoRow(
                icon: AppIcons.coop,
                label: l.chickenAndCoop,
                onTap: onEdit,
                child: coop.isEmpty && note.isEmpty
                    ? Text(
                        l.noCoop,
                        style: AppFont.label.copyWith(
                          color: AppColor.green700,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColor.mintLine,
                        ),
                      )
                    : Text(
                        <String>[
                          if (coop.isNotEmpty) coop,
                          if (note.isNotEmpty) note,
                        ].join(' · '),
                        style: AppFont.label,
                      ),
              ),
              const Divider(),
              _InfoRow(
                icon: statusIcon(record.status),
                label: l.statusLabel,
                child: Pill(
                  label: switch (record.status) {
                    'healthy' => l.healthy,
                    'disease' => l.diseased,
                    _ => l.inconclusive,
                  },
                  ink: statusInk(record.status),
                  fill: severityFill(condition),
                  icon: statusIcon(record.status),
                ),
              ),
            ],
          ),
        ),

        if (condition.spread != null || condition.zoonotic != null) ...<Widget>[
          const SizedBox(height: Insets.md),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (condition.spread != null)
                  Expanded(
                    child: FactTile(
                      icon: AppIcons.spread,
                      label: l.spread,
                      value: condition.spread!(lang),
                    ),
                  ),
                if (condition.spread != null && condition.zoonotic != null)
                  const SizedBox(width: 10),
                if (condition.zoonotic != null)
                  Expanded(
                    child: FactTile(
                      icon: AppIcons.people,
                      label: l.riskToPeople,
                      value: condition.zoonotic!(lang),
                    ),
                  ),
              ],
            ),
          ),
        ],

        if (condition.law != null) ...<Widget>[
          const SizedBox(height: Insets.md),
          Callout(
            icon: AppIcons.law,
            title: l.requiredByLaw,
            body: condition.law!(lang),
            ink: AppColor.caution,
            fill: AppColor.cautionSoft,
          ),
        ],

        // What → why → what to do → when to call, one tap each.
        const SizedBox(height: Insets.section),
        Text(l.whatNext, style: AppFont.h3),
        const SizedBox(height: 10),
        _JumpRow(
          icon: AppIcons.scores,
          label: l.quickWhy,
          onTap: () => jumpTo(_Tab.analysis),
        ),
        _JumpRow(
          icon: AppIcons.tabCare,
          label: l.quickDo,
          onTap: () => jumpTo(_Tab.care),
        ),
        _JumpRow(
          icon: AppIcons.tabVet,
          label: l.quickVet,
          onTap: () => jumpTo(_Tab.vet),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget child;
  final VoidCallback? onTap;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Widget row = Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: AppColor.ink3),
          const SizedBox(width: 10),
          Text(label, style: AppFont.bodySm.copyWith(color: AppColor.ink2)),
          const SizedBox(width: 12),
          Expanded(
            child: Align(alignment: Alignment.centerRight, child: child),
          ),
          if (onTap != null) ...<Widget>[
            const SizedBox(width: 4),
            const Icon(AppIcons.chevron, size: 16, color: AppColor.ink3),
          ],
        ],
      ),
    );
    return onTap == null ? row : InkWell(onTap: onTap, child: row);
  }
}

class _JumpRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _JumpRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Material(
      color: AppColor.surface,
      borderRadius: BorderRadius.circular(Insets.rMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(Insets.rMd),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Insets.rMd),
            border: Border.all(color: AppColor.line),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColor.mintSoft,
                  borderRadius: BorderRadius.circular(Insets.rSm),
                ),
                child: Icon(icon, size: 18, color: AppColor.green900),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: AppFont.label)),
              const Icon(AppIcons.chevron, size: 18, color: AppColor.ink3),
            ],
          ),
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────
// AI Analysis
// ─────────────────────────────────────────────────────────────────────────

/// What the model said and what can honestly be shown about why.
///
/// The model is a whole-image classifier: one score per result, nothing
/// else. It does not produce colour or texture percentages, so this tab does
/// not show any. It shows what is real — the four scores, the lead over the
/// runner-up, colours the app measured in the photo (labelled as the app's
/// measurement), the photo-quality checks, and on the phone an occlusion map
/// of which parts of the photo the answer depended on.
class _AnalysisTab extends StatelessWidget {
  final ScanRecord record;

  const _AnalysisTab({required this.record});

  @override
  Widget build(BuildContext context) {
    final L l = L.of(context);
    final Lang lang = l.lang;
    final bool hasScores = record.scores.isNotEmpty && !record.photoRejected;
    final String top = record.label;
    final Condition topCondition = conditionFor(top.isEmpty ? null : top);
    final String name = topCondition.name(lang);

    final List<double> sorted = record.scores.values.toList()
      ..sort((double a, double b) => b.compareTo(a));
    final int leadPoints = sorted.length >= 2
        ? ((sorted[0] - sorted[1]) * 100).round()
        : 100;
    final bool clearLead = leadPoints >= (Decision.marginBar * 100).round();

    final List<Say> typical = topCondition.signs.isEmpty
        ? const <Say>[]
        : topCondition.signs.first.items;
    // Signs in the bird and across the flock. The droppings group is already
    // shown just above, next to the measured colours.
    final List<SignGroup> inBirds = topCondition.signs.skip(1).toList();
    final Set<String> warningSigns = careFor(topCondition.key).warningSigns;

    return _TabList(
      children: <Widget>[
        if (hasScores) ...<Widget>[
          // The score, big, with the bar it had to clear.
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l.aiScore.toUpperCase(),
                  style: AppFont.micro.copyWith(color: AppColor.ink3),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Expanded(child: Text(name, style: AppFont.h2)),
                    Text(
                      '${(record.confidence * 100).round()}%',
                      style: AppFont.figure.copyWith(fontSize: 30),
                    ),
                  ],
                ),
                const SizedBox(height: Insets.md),
                CertaintyMeter(
                  value: record.confidence,
                  bar: Decision.barFor(top),
                  bandLabel: switch (Decision.bandFor(record.confidence)) {
                    CertaintyBand.strong => l.strongMatch,
                    CertaintyBand.likely => l.likelyMatch,
                    CertaintyBand.below => l.belowBar,
                  },
                  passed: record.confidence >= Decision.barFor(top),
                  ink: severityInk(topCondition),
                ),
              ],
            ),
          ),

          const SizedBox(height: Insets.section),
          SectionHead(icon: AppIcons.info, label: l.whyTitle(name)),
          Text(l.whyIntro, style: AppFont.body.copyWith(color: AppColor.ink2)),

          // 1. The four scores side by side.
          const SizedBox(height: Insets.lg),
          Text(l.howCompared, style: AppFont.h3),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ScoreBars(scores: record.scores, top: top),
                const Divider(),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(
                      clearLead ? AppIcons.healthy : AppIcons.unsure,
                      size: 18,
                      color: clearLead ? AppColor.green700 : AppColor.caution,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(l.lead(leadPoints), style: AppFont.label),
                          const SizedBox(height: 2),
                          Text(
                            clearLead ? l.leadClear : l.leadNarrow,
                            style: AppFont.bodySm.copyWith(
                              color: AppColor.ink2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],

        // 2. Colours the app measured in the photo.
        const SizedBox(height: Insets.lg),
        Text(l.coloursTitle, style: AppFont.h3),
        const SizedBox(height: 4),
        Text(
          l.coloursNote,
          style: AppFont.bodySm.copyWith(color: AppColor.ink3),
        ),
        const SizedBox(height: 12),
        _ColoursCard(record: record),
        if (typical.isNotEmpty) ...<Widget>[
          const SizedBox(height: 10),
          AppCard(
            color: AppColor.bg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(l.typicalFor(name), style: AppFont.label),
                const SizedBox(height: 8),
                ...typical.map(
                  (Say s) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          margin: const EdgeInsets.only(top: 7, right: 10),
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: AppColor.ink3,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(child: Text(s(lang), style: AppFont.bodySm)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // 3. The signs, as a way to check the answer against the birds.
        //    This replaced a tick-box Symptoms tab: ticking only ever led to
        //    "call a vet" or the same general advice, so it was work for the
        //    farmer with nothing new at the end. As a reference beside the
        //    AI's answer it does a real job — it tells them what would confirm
        //    it.
        if (inBirds.isNotEmpty) ...<Widget>[
          const SizedBox(height: Insets.lg),
          SectionHead(icon: AppIcons.lookFor, label: l.confirmTitle),
          Text(
            l.confirmNote,
            style: AppFont.bodySm.copyWith(color: AppColor.ink2),
          ),
          for (final SignGroup g in inBirds) ...<Widget>[
            const SizedBox(height: 12),
            Text(g.where(lang), style: AppFont.label),
            const SizedBox(height: 6),
            AppCard(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 4),
              child: Column(
                children: g.items
                    .map(
                      (Say s) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Container(
                              margin: const EdgeInsets.only(top: 8, right: 10),
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                color: AppColor.ink3,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Expanded(child: Text(s(lang), style: AppFont.body)),
                            if (warningSigns.contains(s.en)) ...<Widget>[
                              const SizedBox(width: 8),
                              Pill(
                                label: l.warningSign,
                                ink: AppColor.danger,
                                fill: AppColor.dangerSoft,
                                icon: AppIcons.warningSign,
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ],
        ],

        // 4. Where the AI looked — measured, on the phone.
        if (hasScores) ...<Widget>[
          const SizedBox(height: Insets.lg),
          Text(l.focusTitle, style: AppFont.h3),
          const SizedBox(height: 4),
          Text(
            l.focusBody,
            style: AppFont.bodySm.copyWith(color: AppColor.ink3),
          ),
          const SizedBox(height: 12),
          _FocusMap(record: record),
        ],

        // 5. The photo checks that ran before the model.
        if (record.quality != null) ...<Widget>[
          const SizedBox(height: Insets.lg),
          SectionHead(icon: AppIcons.photoQuality, label: l.photoQuality),
          QualityPanel(quality: record.quality!),
        ],

        const SizedBox(height: Insets.lg),
        Callout(
          icon: AppIcons.info,
          title: l.pleaseNote,
          body: l.aiDisclaimer,
          ink: AppColor.info,
          fill: AppColor.infoSoft,
        ),
      ],
    );
  }
}

/// Colour shares measured in the photo, as labelled bars with a swatch.
class _ColoursCard extends StatefulWidget {
  final ScanRecord record;

  const _ColoursCard({required this.record});

  @override
  State<_ColoursCard> createState() => _ColoursCardState();
}

class _ColoursCardState extends State<_ColoursCard> {
  Future<ColourProfile?>? _profile;

  @override
  void initState() {
    super.initState();
    if (_hasPhoto(widget.record)) {
      _profile = File(widget.record.imagePath)
          .readAsBytes()
          .then((Uint8List b) => compute(measureColours, b))
          .catchError((Object _) => null);
    }
  }

  static const Map<ColourFamily, Color> _swatch = <ColourFamily, Color>{
    ColourFamily.green: Color(0xFF4E8A3E),
    ColourFamily.brown: Color(0xFF6B4A2B),
    ColourFamily.white: Color(0xFFE6E2D8),
    ColourFamily.red: Color(0xFFC0392B),
    ColourFamily.yellow: Color(0xFFD1AE14),
  };

  @override
  Widget build(BuildContext context) {
    final L l = L.of(context);
    if (_profile == null) return _Note(text: l.noPhotoSaved);
    return FutureBuilder<ColourProfile?>(
      future: _profile,
      builder: (BuildContext context, AsyncSnapshot<ColourProfile?> snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const _Loading();
        }
        final ColourProfile? p = snap.data;
        if (p == null) return _Note(text: l.noPhotoSaved);
        final List<MapEntry<ColourFamily, double>> rows =
            p.shares.entries.toList()..sort(
              (
                MapEntry<ColourFamily, double> a,
                MapEntry<ColourFamily, double> b,
              ) => b.value.compareTo(a.value),
            );
        return AppCard(
          child: Column(
            children: rows
                .map((MapEntry<ColourFamily, double> e) {
                  final int pct = (e.value * 100).round();
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: _swatch[e.key],
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColor.line),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 118,
                          child: Text(
                            l.colourName(e.key.name),
                            style: AppFont.bodySm,
                          ),
                        ),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(Insets.rFull),
                            child: LinearProgressIndicator(
                              value: e.value.clamp(0.0, 1.0),
                              minHeight: 8,
                              backgroundColor: AppColor.fill,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColor.steps,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 44,
                          child: Text(
                            '$pct%',
                            textAlign: TextAlign.right,
                            style: AppFont.labelSm,
                          ),
                        ),
                      ],
                    ),
                  );
                })
                .toList(growable: false),
          ),
        );
      },
    );
  }
}

/// The occlusion map: the photo with its squares shaded by how much each
/// one mattered. Runs only when asked, because it runs the model 17 times.
class _FocusMap extends StatefulWidget {
  final ScanRecord record;

  const _FocusMap({required this.record});

  @override
  State<_FocusMap> createState() => _FocusMapState();
}

class _FocusMapState extends State<_FocusMap> {
  static const int _grid = 4;

  bool _working = false;
  double _progress = 0;
  List<double>? _weights;
  double _aspect = 4 / 3;
  bool _failed = false;

  Future<void> _run() async {
    final Classifier classifier = context.read<Classifier>();
    setState(() {
      _working = true;
      _failed = false;
      _progress = 0;
    });
    try {
      final Uint8List bytes = await File(widget.record.imagePath).readAsBytes();
      final ui.Image decoded = await decodeImageFromList(bytes);
      _aspect = decoded.width / decoded.height;
      decoded.dispose();
      final List<double>? w = await classifier.explain(
        bytes,
        widget.record.label,
        grid: _grid,
        onProgress: (double p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      if (!mounted) return;
      setState(() {
        _weights = w;
        _failed = w == null;
        _working = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _working = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final L l = L.of(context);
    final bool ready = context.read<Classifier>().isReady;

    if (!_hasPhoto(widget.record)) {
      return _Note(text: kIsWeb ? l.focusPhoneOnly : l.noPhotoSaved);
    }
    if (!ready) return _Note(text: l.modelUnavailable);

    final List<double>? w = _weights;
    if (w == null) {
      if (_working) {
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(l.focusWorking, style: AppFont.label),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(Insets.rFull),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 6,
                  backgroundColor: AppColor.fill,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColor.green700,
                  ),
                ),
              ),
            ],
          ),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (_failed) ...<Widget>[
            _Note(text: l.analysisFailed),
            const SizedBox(height: 10),
          ],
          OutlinedButton.icon(
            onPressed: _run,
            icon: const Icon(AppIcons.scores, size: 18),
            label: Text(l.focusButton),
          ),
        ],
      );
    }

    final bool flat = w.every((double v) => v == 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(Insets.rLg),
          child: AspectRatio(
            aspectRatio: _aspect,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                // Fill, not cover: the model saw the whole frame squeezed to
                // a square, so the grid lines up with the photo's own edges.
                Image.file(
                  File(widget.record.imagePath),
                  fit: BoxFit.fill,
                  cacheWidth: 900,
                ),
                Column(
                  children: List<Widget>.generate(_grid, (int y) {
                    return Expanded(
                      child: Row(
                        children: List<Widget>.generate(_grid, (int x) {
                          final double v = w[y * _grid + x];
                          return Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Color.lerp(
                                  const Color(0x99000000),
                                  const Color(0x00000000),
                                  v,
                                ),
                                border: Border.all(
                                  color: v > 0.6
                                      ? AppColor.referenceAccent
                                      : const Color(0x33FFFFFF),
                                  width: v > 0.6 ? 2 : 0.5,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          flat ? l.focusNone : l.focusBody,
          style: AppFont.bodySm.copyWith(color: AppColor.ink3),
        ),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  final String text;

  const _Note({required this.text});

  @override
  Widget build(BuildContext context) => AppCard(
    color: AppColor.bg,
    child: Row(
      children: <Widget>[
        const Icon(AppIcons.info, size: 18, color: AppColor.ink3),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppFont.bodySm.copyWith(color: AppColor.ink2),
          ),
        ),
      ],
    ),
  );
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const AppCard(
    child: Center(
      child: SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2.2),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────
// Recommendations
// ─────────────────────────────────────────────────────────────────────────

class _CareTab extends StatelessWidget {
  final Condition condition;

  const _CareTab({required this.condition});

  @override
  Widget build(BuildContext context) {
    final L l = L.of(context);
    final Lang lang = l.lang;
    final CarePlan care = careFor(condition.key);

    final List<(IconData, String, List<Say>)> groups =
        <(IconData, String, List<Say>)>[
          (AppIcons.careKit, l.careSupportive, care.supportive),
          (AppIcons.supplements, l.careSupplements, care.supplements),
          (AppIcons.foodWater, l.careFood, care.foodWater),
          (AppIcons.coop, l.careIsolation, care.isolation),
          (AppIcons.lookFor, l.careMonitoring, care.monitoring),
        ].where(((IconData, String, List<Say>) g) => g.$3.isNotEmpty).toList();

    return _TabList(
      children: <Widget>[
        if (condition.firstDay.isNotEmpty) ...<Widget>[
          SectionHead(icon: AppIcons.firstDay, label: l.first24),
          StepRail(steps: condition.firstDay, accent: AppColor.steps),
          const SizedBox(height: Insets.section),
        ],
        if (condition.thisWeek.isNotEmpty) ...<Widget>[
          SectionHead(icon: AppIcons.thisWeek, label: l.thisWeek),
          StepRail(steps: condition.thisWeek, accent: AppColor.steps),
          const SizedBox(height: Insets.section),
        ],
        if (groups.isNotEmpty) ...<Widget>[
          SectionHead(icon: AppIcons.tabCare, label: l.careTitle),
          Callout(
            icon: AppIcons.info,
            title: l.careTitle,
            body: l.careDisclaimer,
            ink: AppColor.info,
            fill: AppColor.infoSoft,
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < groups.length; i++)
            _CareGroup(
              icon: groups[i].$1,
              title: groups[i].$2,
              items: groups[i].$3.map((Say s) => s(lang)).toList(),
              startOpen: i == 0,
            ),
        ],
        if (condition.neverDo.isNotEmpty) ...<Widget>[
          const SizedBox(height: Insets.md),
          Callout(
            icon: AppIcons.neverDo,
            title: l.neverDo,
            bullets: condition.neverDo.map((Say s) => s(lang)).toList(),
            ink: AppColor.danger,
            fill: AppColor.dangerSoft,
          ),
        ],
      ],
    );
  }
}

/// One expandable group of recommendations, so the tab opens short.
class _CareGroup extends StatefulWidget {
  final IconData icon;
  final String title;
  final List<String> items;
  final bool startOpen;

  const _CareGroup({
    required this.icon,
    required this.title,
    required this.items,
    required this.startOpen,
  });

  @override
  State<_CareGroup> createState() => _CareGroupState();
}

class _CareGroupState extends State<_CareGroup> {
  late bool _open = widget.startOpen;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(Insets.rMd),
        border: Border.all(color: AppColor.line),
      ),
      child: Column(
        children: <Widget>[
          Semantics(
            button: true,
            expanded: _open,
            child: InkWell(
              onTap: () => setState(() => _open = !_open),
              child: Container(
                constraints: const BoxConstraints(minHeight: 56),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColor.mintSoft,
                        borderRadius: BorderRadius.circular(Insets.rSm),
                      ),
                      child: Icon(
                        widget.icon,
                        size: 18,
                        color: AppColor.green900,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(widget.title, style: AppFont.h3)),
                    AnimatedRotation(
                      turns: _open ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        AppIcons.expand,
                        size: 18,
                        color: AppColor.ink3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: !_open
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.fromLTRB(60, 0, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: widget.items
                          .map(
                            (String t) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  const Padding(
                                    padding: EdgeInsets.only(top: 3),
                                    child: Icon(
                                      AppIcons.check,
                                      size: 14,
                                      color: AppColor.green700,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(t, style: AppFont.body)),
                                ],
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────
// Vet care
// ─────────────────────────────────────────────────────────────────────────

class _VetTab extends StatelessWidget {
  final Condition condition;

  const _VetTab({required this.condition});

  @override
  Widget build(BuildContext context) {
    final L l = L.of(context);
    final Lang lang = l.lang;
    final CarePlan care = careFor(condition.key);
    final List<Say> warnings = <Say>[
      for (final SignGroup g in condition.signs)
        for (final Say s in g.items)
          if (care.warningSigns.contains(s.en)) s,
    ];

    Widget bullet(String text, {bool red = false}) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              AppIcons.warningSign,
              size: 16,
              color: red ? AppColor.danger : AppColor.caution,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppFont.body)),
        ],
      ),
    );

    return _TabList(
      children: <Widget>[
        // The buttons come first: on this tab, calling is the point.
        Text(l.needHelp, style: AppFont.h2),
        const SizedBox(height: 12),
        const VetContactButtons(),

        const SizedBox(height: Insets.lg),
        Text(l.callNowTitle, style: AppFont.h3),
        const SizedBox(height: 10),
        AppCard(
          child: Column(
            children: kCallNowIf
                .map((Say s) => bullet(s(lang)))
                .toList(growable: false),
          ),
        ),

        if (warnings.isNotEmpty) ...<Widget>[
          const SizedBox(height: Insets.lg),
          Text(l.forThisResult, style: AppFont.h3),
          const SizedBox(height: 10),
          AppCard(
            child: Column(
              children: warnings
                  .map((Say s) => bullet(s(lang), red: true))
                  .toList(growable: false),
            ),
          ),
        ],

        const SizedBox(height: Insets.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(condition.escalate(lang), style: AppFont.body),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                l.notADiagnosis,
                style: AppFont.bodySm.copyWith(color: AppColor.ink2),
              ),
            ],
          ),
        ),

        if (condition.law != null) ...<Widget>[
          const SizedBox(height: Insets.md),
          Callout(
            icon: AppIcons.law,
            title: l.requiredByLaw,
            body: condition.law!(lang),
            ink: AppColor.caution,
            fill: AppColor.cautionSoft,
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Photo
// ─────────────────────────────────────────────────────────────────────────

/// The scanned photo at the top of Overview. Tapping opens it full screen.
class _ScanPhoto extends StatelessWidget {
  final File file;

  const _ScanPhoto({required this.file});

  @override
  Widget build(BuildContext context) {
    final L l = L.of(context);
    return Semantics(
      button: true,
      label: l.tapToZoom,
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => _FullScreenPhoto(file: file)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Insets.rLg),
          child: Stack(
            children: <Widget>[
              AspectRatio(
                aspectRatio: 4 / 3,
                child: Image.file(
                  file,
                  fit: BoxFit.cover,
                  cacheWidth: 1000,
                  errorBuilder: (_, _, _) => const ColoredBox(
                    color: AppColor.fill,
                    child: Icon(
                      AppIcons.imageBroken,
                      size: 40,
                      color: AppColor.ink3,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x99000000),
                    borderRadius: BorderRadius.circular(Insets.rFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(
                        AppIcons.fullScreen,
                        size: 15,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l.tapToZoom,
                        style: AppFont.labelSm.copyWith(color: Colors.white),
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

class _FullScreenPhoto extends StatelessWidget {
  final File file;

  const _FullScreenPhoto({required this.file});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black,
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    body: InteractiveViewer(
      maxScale: 5,
      child: Center(child: Image.file(file, fit: BoxFit.contain)),
    ),
  );
}
