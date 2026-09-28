import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/icons.dart';
import '../../core/strings.dart';
import '../../core/tokens.dart';
import '../../data/contacts.dart';
import 'common.dart';
import 'labels_form.dart';

String contactLabel(L l, ContactKind k) => switch (k) {
  ContactKind.vet => l.contactVet,
  ContactKind.poultry => l.contactPoultry,
  ContactKind.office => l.contactOffice,
};

/// Opens the phone's dialer with the number filled in. The farmer still
/// presses call — nothing is dialled on their behalf.
Future<void> callContact(BuildContext context, VetContact c) async {
  final L l = L.of(context);
  bool ok = false;
  try {
    ok = await launchUrl(Uri(scheme: 'tel', path: c.dialable));
  } catch (_) {
    ok = false;
  }
  if (!ok && context.mounted) showToast(context, l.callFailed);
}

/// The three call buttons. A saved number is a big button that opens the
/// dialer; an empty one offers to add the number instead of pretending to
/// have one.
class VetContactButtons extends StatelessWidget {
  const VetContactButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final L l = L.of(context);
    final ContactStore store = context.watch<ContactStore>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final VetContact c in store.all) ...<Widget>[
          _CallButton(
            contact: c,
            label: contactLabel(l, c.kind),
            primary: c.kind == ContactKind.vet,
          ),
          const SizedBox(height: 10),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => editContacts(context),
            icon: const Icon(AppIcons.edit, size: 18),
            label: Text(l.editNumbers),
          ),
        ),
      ],
    );
  }
}

class _CallButton extends StatelessWidget {
  final VetContact contact;
  final String label;
  final bool primary;

  const _CallButton({
    required this.contact,
    required this.label,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final L l = L.of(context);
    final bool has = contact.hasNumber;
    final Color fill = !has
        ? AppColor.surface
        : primary
        ? AppColor.green900
        : AppColor.mint;
    final Color ink = !has
        ? AppColor.ink2
        : primary
        ? AppColor.onDark
        : AppColor.green900;
    final String sub = !has
        ? l.addNumber
        : contact.name.trim().isEmpty
        ? contact.number
        : '${contact.name.trim()} · ${contact.number}';

    return Semantics(
      button: true,
      label: has ? l.callWho(label) : '${l.addNumber}: $label',
      excludeSemantics: true,
      child: Material(
        color: fill,
        borderRadius: BorderRadius.circular(Insets.rMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(Insets.rMd),
          onTap: () =>
              has ? callContact(context, contact) : editContacts(context),
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Insets.rMd),
              border: has ? null : Border.all(color: AppColor.line),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: has
                        ? (primary ? const Color(0x26FFFFFF) : AppColor.surface)
                        : AppColor.fill,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    has ? AppIcons.phone : AppIcons.edit,
                    size: 20,
                    color: ink,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        has ? l.callWho(label) : label,
                        style: AppFont.label.copyWith(
                          color: ink,
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFont.bodySm.copyWith(
                          color: primary && has ? AppColor.mint : AppColor.ink3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A sheet to type in the three numbers.
Future<void> editContacts(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (_) => const _ContactsSheet(),
);

class _ContactsSheet extends StatefulWidget {
  const _ContactsSheet();

  @override
  State<_ContactsSheet> createState() => _ContactsSheetState();
}

class _ContactsSheetState extends State<_ContactsSheet> {
  late final Map<ContactKind, TextEditingController> _names;
  late final Map<ContactKind, TextEditingController> _numbers;

  @override
  void initState() {
    super.initState();
    final ContactStore store = context.read<ContactStore>();
    _names = <ContactKind, TextEditingController>{
      for (final VetContact c in store.all)
        c.kind: TextEditingController(text: c.name),
    };
    _numbers = <ContactKind, TextEditingController>{
      for (final VetContact c in store.all)
        c.kind: TextEditingController(text: c.number),
    };
  }

  @override
  void dispose() {
    for (final TextEditingController c in <TextEditingController>[
      ..._names.values,
      ..._numbers.values,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final ContactStore store = context.read<ContactStore>();
    for (final ContactKind k in ContactKind.values) {
      store.save(
        store
            .of(k)
            .copyWith(
              name: _names[k]!.text.trim(),
              number: _numbers[k]!.text.trim(),
            ),
      );
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final L l = L.of(context);
    return SheetFrame(
      children: <Widget>[
        Text(l.contactsTitle, style: AppFont.h2),
        const SizedBox(height: 6),
        Text(
          l.contactsNote,
          style: AppFont.bodySm.copyWith(color: AppColor.ink2),
        ),
        for (final ContactKind k in ContactKind.values) ...<Widget>[
          const SizedBox(height: Insets.lg),
          Text(contactLabel(l, k), style: AppFont.h3),
          const SizedBox(height: 10),
          TextField(
            controller: _numbers[k],
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: l.phoneNumber,
              hintText: '09XX XXX XXXX',
              floatingLabelBehavior: FloatingLabelBehavior.always,
              prefixIcon: const Icon(AppIcons.phone, size: 18),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _names[k],
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: l.nameOptional,
              floatingLabelBehavior: FloatingLabelBehavior.always,
            ),
          ),
        ],
        const SizedBox(height: Insets.lg),
        ElevatedButton(onPressed: _save, child: Text(l.save)),
      ],
    );
  }
}
