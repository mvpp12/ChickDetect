import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// "Scan again in 3 days" reminders after a sick result.
///
/// The Records page can only say "better / worse than before" if the farmer
/// actually scans again, and after a bad result that second scan is exactly
/// what gets forgotten. One local notification, on this phone, no internet.
///
/// Due dates are also kept in preferences so a result sheet can show
/// "Reminder set for …" and the reminder can be cancelled with its scan.
class RescanReminders {
  RescanReminders._();

  static const String _key = 'rescan_reminders_v1';
  static const String _channelId = 'rescan';
  static const String _channelName = 'Rescan reminders';
  static const int days = 3;

  /// Morning, when farmers feed and check the flock.
  static const int _hour = 8;

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static Future<void> _init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    _ready = true;
  }

  /// Notification ids must fit in 32 bits; scan ids are milliseconds.
  static int _notificationId(int scanId) => (scanId ~/ 1000) & 0x7fffffff;

  static Future<Map<String, String>> _load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return <String, String>{};
      return Map<String, String>.from(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return <String, String>{};
    }
  }

  static Future<void> _save(Map<String, String> due) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(due));
    } catch (_) {
      // Only the "Reminder set" label is lost; the notification still fires.
    }
  }

  /// When the reminder for [scanId] is due, or null if there is none.
  static Future<DateTime?> dueFor(int scanId) async {
    final String? iso = (await _load())['$scanId'];
    final DateTime? at = iso == null ? null : DateTime.tryParse(iso);
    return at != null && at.isAfter(DateTime.now()) ? at : null;
  }

  /// Schedules the reminder. Returns the due time, or null when the farmer
  /// has notifications turned off (Android 13+ asks first).
  static Future<DateTime?> schedule({
    required int scanId,
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return null;
    await _init();
    final AndroidFlutterLocalNotificationsPlugin? android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final bool allowed =
        await android?.requestNotificationsPermission() ?? false;
    if (!allowed) return null;

    final DateTime now = DateTime.now();
    final DateTime due = DateTime(now.year, now.month, now.day + days, _hour);
    await _plugin.zonedSchedule(
      id: _notificationId(scanId),
      // An absolute instant, so UTC is enough; no device time zone lookup.
      scheduledDate: tz.TZDateTime.from(due, tz.UTC),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      // Inexact: needs no special alarm permission, and a few minutes late
      // does not matter for a reminder three days out.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      title: title,
      body: body,
    );
    final Map<String, String> all = await _load();
    all['$scanId'] = due.toIso8601String();
    await _save(all);
    return due;
  }

  static Future<void> cancel(int scanId) async {
    final Map<String, String> all = await _load();
    if (all.remove('$scanId') == null) return;
    await _save(all);
    if (kIsWeb) return;
    try {
      await _init();
      await _plugin.cancel(id: _notificationId(scanId));
    } catch (_) {
      // Nothing scheduled, or the plugin is unavailable; either way it is gone.
    }
  }

  static Future<void> cancelAll() async {
    final Map<String, String> all = await _load();
    if (all.isEmpty) return;
    await _save(<String, String>{});
    if (kIsWeb) return;
    try {
      await _init();
      await _plugin.cancelAll();
    } catch (_) {}
  }
}
