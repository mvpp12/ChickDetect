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
import 'widgets/common.dart';
import 'widgets/labels_form.dart';
import 'widgets/report.dart';

/// The full record of one scan.
///
/// Reads the record from the store by id rather than taking a copy, so edits
/// made here — renaming a coop, deleting — are reflected everywhere at once.
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

    return Scaffold(
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Insets.screen,
          Insets.sm,
          Insets.screen,
          Insets.xxl,
        ),
        children: <Widget>[
          _Photo(record: r, condition: condition),
          const SizedBox(height: 12),
          _Meta(record: r, onEdit: () => _editLabels(context, r)),
          const SizedBox(height: Insets.lg),
          ConditionReport(
            condition: condition,
            depth: ReportDepth.full,
            confidence: r.photoRejected ? null : r.confidence,
            rawLabel: r.label.isEmpty ? null : r.label,
            scores: r.scores.isEmpty ? null : r.scores,
            quality: r.quality,
          ),
        ],
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
    // This used to show the "delete everything" warning for a single scan.
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

class _Photo extends StatelessWidget {
  final ScanRecord record;
  final Condition condition;

  const _Photo({required this.record, required this.condition});

  @override
  Widget build(BuildContext context) {
    final L l = L.of(context);
    final Color ink = severityInk(condition);

    return ClipRRect(
      borderRadius: BorderRadius.circular(Insets.rLg),
      child: Stack(
        children: <Widget>[
          SizedBox(
            height: 260,
            width: double.infinity,
            child: record.imagePath.isEmpty
                ? const ColoredBox(
                    color: AppColor.fill,
                    child: Icon(AppIcons.imageBroken,
                        size: 46, color: AppColor.ink3),
                  )
                : Image.file(
                    File(record.imagePath),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const ColoredBox(
                      color: AppColor.fill,
                      child: Icon(AppIcons.imageBroken,
                          size: 46, color: AppColor.ink3),
                    ),
                  ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 26, 14, 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[Color(0x00000000), Color(0xCC000000)],
                ),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 5, 12, 5),
                  decoration: BoxDecoration(
                    color: severityFill(condition),
                    borderRadius: BorderRadius.circular(Insets.rFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(severityIcon(condition), size: 15, color: ink),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          condition.name(l.lang),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFont.labelSm.copyWith(
                            color: ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final ScanRecord record;
  final VoidCallback onEdit;

  const _Meta({required this.record, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final L l = L.of(context);
    final String coop = record.coop.trim();
    final String note = record.note.trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // An unnamed scan says so, and offers the fix in place. It used
              // to print the word "Coop" as if that were the coop's name.
              if (coop.isEmpty)
                InkWell(
                  onTap: onEdit,
                  borderRadius: BorderRadius.circular(Insets.rSm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(AppIcons.coop,
                            size: 17, color: AppColor.green700),
                        const SizedBox(width: 7),
                        Text(
                          l.noCoop,
                          style: AppFont.label.copyWith(
                            color: AppColor.green700,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColor.mintLine,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Row(
                  children: <Widget>[
                    const Icon(AppIcons.coop, size: 17, color: AppColor.ink2),
                    const SizedBox(width: 7),
                    Expanded(child: Text(coop, style: AppFont.h3)),
                  ],
                ),
              if (note.isNotEmpty) ...<Widget>[
                const SizedBox(height: 2),
                Text(
                  note,
                  style: AppFont.bodySm.copyWith(color: AppColor.ink2),
                ),
              ],
              const SizedBox(height: 3),
              Text(
                DateFormat('d MMMM y · h:mm a').format(record.at),
                style: AppFont.labelSm.copyWith(color: AppColor.ink3),
              ),
            ],
          ),
        ),
        if (record.photoRejected)
          Pill(
            label: l.photoRejected,
            ink: AppColor.caution,
            fill: AppColor.cautionSoft,
            icon: AppIcons.rejected,
          ),
      ],
    );
  }
}
