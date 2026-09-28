import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The three kinds of help the Vet Care buttons can call.
enum ContactKind { vet, poultry, office }

class VetContact {
  final ContactKind kind;

  /// Optional — "Dr. Santos", "MAO San Jose". Blank shows the kind's label.
  final String name;
  final String number;

  const VetContact({required this.kind, this.name = '', this.number = ''});

  bool get hasNumber => number.trim().isNotEmpty;

  /// Digits, spaces removed, a leading + kept — what the dialer is given.
  String get dialable => number.replaceAll(RegExp(r'[^0-9+]'), '');

  VetContact copyWith({String? name, String? number}) => VetContact(
    kind: kind,
    name: name ?? this.name,
    number: number ?? this.number,
  );

  Map<String, String> toJson() => <String, String>{
    'name': name,
    'number': number,
  };
}

/// The farmer's own vet and office numbers, kept on the phone.
///
/// The app ships with none filled in, deliberately. A hotline number that is
/// wrong, out of date or for another province is worse than no number: it
/// fails at exactly the moment it is needed. The farmer saves the numbers they
/// actually use — their municipal agriculture office, their vet — and the call
/// buttons dial those.
class ContactStore extends ChangeNotifier {
  static const String _key = 'vet_contacts_v1';

  final Map<ContactKind, VetContact> _items = <ContactKind, VetContact>{
    for (final ContactKind k in ContactKind.values) k: VetContact(kind: k),
  };

  List<VetContact> get all =>
      ContactKind.values.map((ContactKind k) => _items[k]!).toList();

  VetContact of(ContactKind k) => _items[k]!;

  bool get anySaved => _items.values.any((VetContact c) => c.hasNumber);

  Future<void> load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_key);
      if (raw != null) {
        final Object? parsed = jsonDecode(raw);
        if (parsed is Map) {
          for (final ContactKind k in ContactKind.values) {
            final Object? v = parsed[k.name];
            if (v is Map) {
              _items[k] = VetContact(
                kind: k,
                name: (v['name'] ?? '').toString(),
                number: (v['number'] ?? '').toString(),
              );
            }
          }
        }
      }
    } catch (_) {
      // No saved contacts is a normal state; the buttons offer to add them.
    }
    notifyListeners();
  }

  Future<void> save(VetContact c) async {
    _items[c.kind] = c;
    notifyListeners();
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode(<String, Object>{
          for (final VetContact v in _items.values) v.kind.name: v.toJson(),
        }),
      );
    } catch (_) {
      // Not fatal: the number works for this session.
    }
  }
}
