import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/icons.dart';
import '../core/strings.dart';
import '../core/tokens.dart';
import '../data/contacts.dart';
import '../data/scan_store.dart';
import '../ml/classifier.dart';
import '../ml/decision.dart';
import 'widgets/common.dart';
import 'widgets/vet_contacts.dart';

/// Language, what the model is, and the data.
///
/// Reached from the gear in the header rather than a tab of its own. Short on
/// purpose: everything here is real, and each thing appears once. The guide
/// replay that used to sit here as well is already one tap away on the Guide
/// tab and behind the camera's help button, so it is not repeated.
///
/// Data tools — the CSV copy and the delete — live together here. The CSV
/// button used to sit at the foot of the records list, below however many
/// scans the farmer had, which is to say where nobody would find it.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final L l = L.of(context);
    final LanguageController? language = LanguageScope.of(context);
    final Classifier classifier = context.read<Classifier>();
    final ScanStore store = context.watch<ScanStore>();

    return Scaffold(
      backgroundColor: AppColor.bg,
      appBar: AppBar(title: Text(l.settings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Insets.screen,
          Insets.sm,
          Insets.screen,
          Insets.xxl,
        ),
        children: <Widget>[
          // ── language ─────────────────────────────────────────────────
          _GroupLabel(icon: AppIcons.language, label: l.language),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _LanguagePicker(
                  current: l.lang,
                  onPick: (Lang v) => language?.set(v),
                ),
                const SizedBox(height: 10),
                Text(
                  l.languageNote,
                  style: AppFont.bodySm.copyWith(color: AppColor.ink3),
                ),
              ],
            ),
          ),

          // ── the model ────────────────────────────────────────────────
          const SizedBox(height: Insets.section),
          _GroupLabel(icon: AppIcons.model, label: l.modelOnPhone),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: Insets.card),
            child: Column(
              children: <Widget>[
                _Fact(
                  label: l.resultsItGives,
                  value: '${classifier.labels.length}',
                ),
                const Divider(),
                // The thresholds are shown because they are the app's actual
                // policy, and a farmer — or an examiner — is entitled to see
                // where the line sits rather than take the word "confident"
                // on trust.
                _Fact(
                  label: l.certaintyNeeded,
                  value:
                      '${(Decision.conditionBar * 100).round()}% · '
                      '${(Decision.healthyBar * 100).round()}% '
                      '${l.healthy.toLowerCase()}',
                ),
              ],
            ),
          ),

          // ── vet contacts ─────────────────────────────────────────────
          // The same numbers the Vet Care tab dials, set up ahead of time.
          const SizedBox(height: Insets.section),
          _GroupLabel(icon: AppIcons.tabVet, label: l.contactsTitle),
          Material(
            color: AppColor.surface,
            borderRadius: BorderRadius.circular(Insets.rLg),
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Insets.rLg),
                border: Border.all(color: AppColor.line),
              ),
              child: _ActionRow(
                icon: AppIcons.phone,
                title: l.editNumbers,
                subtitle: context.watch<ContactStore>().anySaved
                    ? context
                          .watch<ContactStore>()
                          .all
                          .where((VetContact c) => c.hasNumber)
                          .map((VetContact c) => contactLabel(l, c.kind))
                          .join(' · ')
                    : l.contactsEmpty,
                onTap: () => editContacts(context),
              ),
            ),
          ),

          // ── data ─────────────────────────────────────────────────────
          const SizedBox(height: Insets.section),
          _GroupLabel(icon: AppIcons.privacy, label: l.yourData),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              l.aboutDataBody,
              style: AppFont.bodySm.copyWith(color: AppColor.ink2),
            ),
          ),
          Material(
            color: AppColor.surface,
            borderRadius: BorderRadius.circular(Insets.rLg),
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Insets.rLg),
                border: Border.all(color: AppColor.line),
              ),
              child: Column(
                children: <Widget>[
                  _ActionRow(
                    icon: AppIcons.exportCsv,
                    title: l.exportCsv,
                    subtitle: l.exportCsvBody,
                    onTap: store.isEmpty
                        ? null
                        : () => _copyCsv(context, store),
                  ),
                  const Divider(indent: 64),
                  _ActionRow(
                    icon: AppIcons.delete,
                    title: l.clearRecords,
                    subtitle: l.countScans(store.items.length),
                    danger: true,
                    onTap: store.isEmpty
                        ? null
                        : () => _confirmClear(context, store),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: Insets.xl),
          Center(
            child: Text(
              '${l.appName} · ${l.version} 2.0',
              style: AppFont.labelSm.copyWith(color: AppColor.ink3),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copyCsv(BuildContext context, ScanStore store) async {
    final L l = L.of(context);
    await Clipboard.setData(ClipboardData(text: store.toCsv()));
    if (!context.mounted) return;
    showToast(context, l.copied);
  }

  Future<void> _confirmClear(BuildContext context, ScanStore store) async {
    final L l = L.of(context);
    final bool yes = await confirmDestructive(
      context,
      title: l.clearRecordsQ,
      body: l.clearRecordsBody,
      action: l.delete,
    );
    if (!yes) return;
    await store.clear();
    if (!context.mounted) return;
    showToast(context, l.recordsDeleted);
  }
}

class _GroupLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _GroupLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 2, bottom: 10),
    child: Row(
      children: <Widget>[
        Icon(icon, size: 17, color: AppColor.green700),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: AppFont.h3)),
      ],
    ),
  );
}

class _LanguagePicker extends StatelessWidget {
  final Lang current;
  final ValueChanged<Lang> onPick;

  const _LanguagePicker({required this.current, required this.onPick});

  @override
  Widget build(BuildContext context) => Segmented<Lang>(
    value: current,
    onChanged: onPick,
    options: const <(Lang, String)>[(Lang.tl, 'Tagalog'), (Lang.en, 'English')],
    height: Insets.tap,
  );
}

class _Fact extends StatelessWidget {
  final String label;
  final String value;

  const _Fact({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 13),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: AppFont.bodySm.copyWith(color: AppColor.ink2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: AppFont.label.copyWith(
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
      ],
    ),
  );
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool danger;

  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null;
    final Color ink = !enabled
        ? AppColor.ink3
        : danger
        ? AppColor.danger
        : AppColor.green900;
    final Color tile = !enabled
        ? AppColor.fill
        : danger
        ? AppColor.dangerSoft
        : AppColor.mintSoft;

    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 68),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: <Widget>[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: tile,
                borderRadius: BorderRadius.circular(Insets.rSm),
              ),
              child: Icon(icon, size: 19, color: ink),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: AppFont.label.copyWith(
                      color: danger && enabled ? AppColor.danger : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppFont.bodySm.copyWith(color: AppColor.ink3),
                  ),
                ],
              ),
            ),
            if (!danger && enabled) ...<Widget>[
              const SizedBox(width: 8),
              const Icon(AppIcons.chevron, size: 18, color: AppColor.ink3),
            ],
          ],
        ),
      ),
    );
  }
}
