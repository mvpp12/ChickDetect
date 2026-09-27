import 'dart:convert';

import '../ml/decision.dart';
import '../ml/image_check.dart';

/// One saved scan.
///
/// Everything needed to re-render the full report is stored, including the raw
/// class scores and the photo-quality figures. The previous version kept only
/// a formatted confidence string, which meant an old scan could never be shown
/// with the detail a newer build could produce — and made the records useless
/// as research data.
class ScanRecord {
  final int id;
  final DateTime at;

  /// Raw model label, not the display name — display names are translated and
  /// would break lookups when the language changes.
  final String label;
  final double confidence;
  final Map<String, double> scores;

  /// 'healthy' | 'disease' | 'inconclusive'
  final String status;

  final String coop;
  final String note;
  final String imagePath;
  final PhotoQuality? quality;

  /// True when the photo was refused before the model ran.
  final bool photoRejected;

  const ScanRecord({
    required this.id,
    required this.at,
    required this.label,
    required this.confidence,
    required this.scores,
    required this.status,
    required this.coop,
    required this.note,
    required this.imagePath,
    required this.quality,
    required this.photoRejected,
  });

  ScanRecord copyWith({String? coop, String? note}) => ScanRecord(
    id: id,
    at: at,
    label: label,
    confidence: confidence,
    scores: scores,
    status: status,
    coop: coop ?? this.coop,
    note: note ?? this.note,
    imagePath: imagePath,
    quality: quality,
    photoRejected: photoRejected,
  );

  /// The condition to look up. A refused photo has no model answer at all.
  String get conditionKey {
    if (photoRejected) return 'inconclusive';
    if (status == 'inconclusive') return 'inconclusive';
    return label;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'at': at.millisecondsSinceEpoch,
    'label': label,
    'confidence': confidence,
    'scores': scores,
    'status': status,
    'coop': coop,
    'note': note,
    'imagePath': imagePath,
    'quality': quality?.toJson(),
    'photoRejected': photoRejected,
  };

  static ScanRecord? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final Object? id = raw['id'];
    if (id is! int) return null;

    final Map<String, double> scores = <String, double>{};
    final Object? rawScores = raw['scores'];
    if (rawScores is Map) {
      rawScores.forEach((Object? k, Object? v) {
        if (k is String && v is num) scores[k] = v.toDouble();
      });
    }

    final Object? at = raw['at'];
    return ScanRecord(
      id: id,
      at: DateTime.fromMillisecondsSinceEpoch(at is int ? at : id),
      label: (raw['label'] ?? '').toString(),
      confidence: raw['confidence'] is num
          ? (raw['confidence'] as num).toDouble()
          : 0,
      scores: scores,
      status: (raw['status'] ?? 'inconclusive').toString(),
      coop: (raw['coop'] ?? '').toString(),
      note: (raw['note'] ?? '').toString(),
      imagePath: (raw['imagePath'] ?? '').toString(),
      quality: PhotoQuality.fromJson(raw['quality']),
      photoRejected: raw['photoRejected'] == true,
    );
  }

  static ScanRecord fromVerdict({
    required Verdict verdict,
    required String imagePath,
    required String coop,
    required String note,
  }) {
    final DateTime now = DateTime.now();
    return ScanRecord(
      id: now.millisecondsSinceEpoch,
      at: now,
      label: verdict.prediction?.label ?? '',
      confidence: verdict.confidence ?? 0,
      scores: verdict.prediction?.scores ?? const <String, double>{},
      status: verdict.status,
      coop: coop,
      note: note,
      imagePath: imagePath,
      quality: verdict.quality,
      photoRejected: verdict.kind == VerdictKind.photoRejected,
    );
  }

  static String encodeList(List<ScanRecord> items) =>
      jsonEncode(items.map((ScanRecord e) => e.toJson()).toList());

  static List<ScanRecord> decodeList(String raw) {
    try {
      final Object? parsed = jsonDecode(raw);
      if (parsed is! List) return <ScanRecord>[];
      return parsed
          .map(ScanRecord.fromJson)
          .whereType<ScanRecord>()
          .toList(growable: false);
    } catch (_) {
      return <ScanRecord>[];
    }
  }
}
