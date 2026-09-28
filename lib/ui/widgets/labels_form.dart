import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/icons.dart';
import '../../core/strings.dart';
import '../../core/tokens.dart';
import '../../data/scan_record.dart';
import '../../data/scan_store.dart';

/// Coop and note for one scan, saved as they are typed.
///
/// One widget for both places a scan gets labelled — straight after the
/// reading, and later from the record itself. Before, the labels could only be
/// set in the result sheet; close it too quickly and the scan stayed "#014"
/// for good.
class ScanLabelsForm extends StatefulWidget {
  final ScanRecord record;

  const ScanLabelsForm({super.key, required this.record});

  @override
  State<ScanLabelsForm> createState() => _ScanLabelsFormState();
}

class _ScanLabelsFormState extends State<ScanLabelsForm> {
  late final TextEditingController _coop;
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    _coop = TextEditingController(text: widget.record.coop);
    _note = TextEditingController(text: widget.record.note);
  }

  @override
  void dispose() {
    _coop.dispose();
    _note.dispose();
    super.dispose();
  }

  void _save() {
    context.read<ScanStore>().update(
      widget.record.copyWith(coop: _coop.text.trim(), note: _note.text.trim()),
    );
  }

  void _pick(String coop) {
    _coop.text = coop;
    _save();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final L l = L.of(context);
    final String current = _coop.text.trim();
    final List<String> coops = context
        .read<ScanStore>()
        .knownCoops
        .where((String c) => c != current)
        .take(4)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TextField(
          controller: _coop,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: l.coop,
            hintText: l.coopHint,
            floatingLabelBehavior: FloatingLabelBehavior.always,
            prefixIcon: const Icon(AppIcons.coop, size: 20),
          ),
          onChanged: (_) {
            _save();
            setState(() {});
          },
        ),
        if (coops.isNotEmpty) ...<Widget>[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: coops
                .map(
                  (String c) => ActionChip(
                    avatar: const Icon(
                      AppIcons.coop,
                      size: 14,
                      color: AppColor.green900,
                    ),
                    label: Text(c),
                    labelStyle: AppFont.labelSm.copyWith(
                      color: AppColor.green900,
                    ),
                    backgroundColor: AppColor.mintSoft,
                    side: const BorderSide(color: AppColor.mintLine),
                    onPressed: () => _pick(c),
                  ),
                )
                .toList(growable: false),
          ),
        ],
        const SizedBox(height: 14),
        TextField(
          controller: _note,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: l.note,
            hintText: l.noteHint,
            floatingLabelBehavior: FloatingLabelBehavior.always,
            prefixIcon: const Icon(AppIcons.note, size: 20),
          ),
          onChanged: (_) => _save(),
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            const Icon(AppIcons.saved, size: 15, color: AppColor.green700),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                l.savedToRecords,
                style: AppFont.labelSm.copyWith(color: AppColor.ink3),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Rounded sheet with a grab handle and keyboard-safe padding. Every bottom
/// sheet in the app is built on this, so they share one shape.
class SheetFrame extends StatelessWidget {
  final List<Widget> children;

  const SheetFrame({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(10),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: BoxDecoration(
          color: AppColor.bg,
          borderRadius: BorderRadius.circular(Insets.rXl),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 4),
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColor.mintLine,
                  borderRadius: BorderRadius.circular(Insets.rFull),
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  Insets.screen,
                  Insets.md,
                  Insets.screen,
                  Insets.lg + bottomInset,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
