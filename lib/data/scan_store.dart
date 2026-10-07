import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'photo_store.dart';
import 'scan_record.dart';

/// Scan history, kept on the phone.
///
/// A [ChangeNotifier] rather than a stream so every screen shows the same list
/// the instant a scan is saved, with no refresh step. Writes are fire-and-
/// forget: the in-memory list is the truth for the session, and a failed write
/// costs the record at next launch rather than blocking the UI now.
class ScanStore extends ChangeNotifier {
  static const String _key = 'scan_records_v2';

  List<ScanRecord> _items = <ScanRecord>[];
  bool _loaded = false;

  /// Newest first.
  List<ScanRecord> get items => List<ScanRecord>.unmodifiable(_items);
  bool get isLoaded => _loaded;
  bool get isEmpty => _items.isEmpty;

  Future<void> load() async {
    if (_loaded) return;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_key);
      if (raw != null && raw.isNotEmpty) {
        _items = ScanRecord.decodeList(raw)
          ..sort((ScanRecord a, ScanRecord b) => b.at.compareTo(a.at));
      }
    } catch (_) {
      _items = <ScanRecord>[];
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> add(ScanRecord record) async {
    _items = <ScanRecord>[record, ..._items];
    notifyListeners();
    await _persist();
  }

  Future<void> update(ScanRecord record) async {
    final int i = _items.indexWhere((ScanRecord e) => e.id == record.id);
    if (i < 0) return;
    final List<ScanRecord> next = List<ScanRecord>.from(_items);
    next[i] = record;
    _items = next;
    notifyListeners();
    await _persist();
  }

  Future<void> remove(int id) => removeMany(<int>{id});

  /// Deletes several scans with one save, and their kept photos with them.
  Future<void> removeMany(Set<int> ids) async {
    if (ids.isEmpty) return;
    final List<ScanRecord> gone = _items
        .where((ScanRecord e) => ids.contains(e.id))
        .toList(growable: false);
    _items = _items
        .where((ScanRecord e) => !ids.contains(e.id))
        .toList(growable: false);
    notifyListeners();
    await _persist();
    for (final ScanRecord r in gone) {
      await dropPhoto(r.imagePath);
    }
  }

  Future<void> clear() async {
    _items = <ScanRecord>[];
    notifyListeners();
    await dropAllPhotos();
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {
      // The list is already empty in memory; the stale copy is overwritten on
      // the next successful write.
    }
  }

  Future<void> _persist() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, ScanRecord.encodeList(_items));
    } catch (_) {
      // Non-fatal by design — see the class comment.
    }
  }

  // ── derived views ──────────────────────────────────────────────────────

  /// Coops the farmer has actually used, most recent first, for suggestions.
  List<String> get knownCoops {
    final List<String> seen = <String>[];
    for (final ScanRecord r in _items) {
      final String c = r.coop.trim();
      if (c.isNotEmpty && !seen.contains(c)) seen.add(c);
    }
    return seen;
  }

  List<ScanRecord> within(Duration window) {
    final DateTime cutoff = DateTime.now().subtract(window);
    return _items
        .where((ScanRecord r) => r.at.isAfter(cutoff))
        .toList(growable: false);
  }

  /// Share of scans in [list] that came back healthy, or null when the sample
  /// is too small to mean anything. Four is arbitrary but honest: a trend
  /// drawn from two scans is noise with a percentage sign on it.
  ///
  /// Only real readings count. A "retake" says the photo was unclear, not that
  /// a bird was unwell; counting it as not-healthy used to make a few blurry
  /// photos look like the flock was getting worse.
  static double? healthyShare(List<ScanRecord> list) {
    final int healthy = list
        .where((ScanRecord r) => r.status == 'healthy')
        .length;
    final int sick = list.where((ScanRecord r) => r.status == 'disease').length;
    if (healthy + sick < 4) return null;
    return healthy / (healthy + sick);
  }

  /// Sequential number shown to the farmer, oldest scan being #001.
  int numberOf(ScanRecord record) {
    final int i = _items.indexWhere((ScanRecord e) => e.id == record.id);
    if (i < 0) return _items.length;
    return _items.length - i;
  }

  /// The whole record as CSV, for pasting into a spreadsheet.
  String toCsv() {
    final StringBuffer b = StringBuffer(
      'number,datetime,coop,note,result,label,confidence,'
      'sharpness,brightness,spread,photo_rejected\n',
    );
    for (int i = 0; i < _items.length; i++) {
      final ScanRecord r = _items[i];
      final int number = _items.length - i;
      String q(String s) => '"${s.replaceAll('"', '""')}"';
      b.writeln(
        <String>[
          number.toString().padLeft(3, '0'),
          r.at.toIso8601String(),
          q(r.coop),
          q(r.note),
          r.status,
          r.label,
          r.confidence.toStringAsFixed(4),
          (r.quality?.sharpness ?? 0).toStringAsFixed(1),
          (r.quality?.brightness ?? 0).toStringAsFixed(1),
          (r.quality?.spread ?? 0).toStringAsFixed(1),
          r.photoRejected ? 'yes' : 'no',
        ].join(','),
      );
    }
    return b.toString();
  }
}
