import 'package:flutter/material.dart';

import 'data/scan_record.dart';
import 'data/scan_store.dart';
import 'main.dart';

/// Browser preview: the real app, started with a handful of sample scans so
/// Records, the detail page and Settings have something to show.
///
///   flutter run -d chrome -t lib/preview_main.dart
///
/// Not used by the Android build, which starts from `main.dart` as always.
/// Every sample is noted "Sample" so it cannot be mistaken for a real reading;
/// "Delete all records" in Settings removes them.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final ScanStore store = ScanStore();
  await store.load();
  if (store.isEmpty) {
    for (final ScanRecord r in _samples()) {
      await store.add(r);
    }
  }

  runApp(ChickDetectApp(store: store));
}

List<ScanRecord> _samples() {
  final DateTime now = DateTime.now();

  ScanRecord make(
    int id,
    Duration ago,
    String label,
    String status,
    double confidence, {
    String coop = '',
  }) {
    final Map<String, double> scores = <String, double>{
      'newcastle': 0.02,
      'salmonella': 0.02,
      'coccidiosis': 0.02,
      'healthy': 0.02,
    };
    scores[label] = confidence;
    return ScanRecord(
      id: id,
      at: now.subtract(ago),
      label: label,
      confidence: confidence,
      scores: scores,
      status: status,
      coop: coop,
      note: 'Sample',
      imagePath: '',
      quality: null,
      photoRejected: false,
    );
  }

  // Oldest first; the store puts the newest at the top.
  return <ScanRecord>[
    make(
      1,
      const Duration(days: 9),
      'healthy',
      'healthy',
      0.93,
      coop: 'Coop A',
    ),
    make(
      2,
      const Duration(days: 4, hours: 3),
      'coccidiosis',
      'disease',
      0.81,
      coop: 'Coop B',
    ),
    make(
      3,
      const Duration(days: 1, hours: 2),
      'healthy',
      'healthy',
      0.90,
      coop: 'Coop A',
    ),
    make(
      5,
      const Duration(hours: 1),
      'newcastle',
      'disease',
      0.88,
      coop: 'Main layer house',
    ),
  ];
}
