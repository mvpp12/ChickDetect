import 'package:flutter/material.dart';

import '../../data/reminders.dart';
import '../../data/scan_record.dart';
import '../../data/scan_store.dart';

/// "Scan deleted · Undo".
///
/// The scans are already out of the list; their photos and reminders are
/// only removed once the message goes away without Undo. One wrong tap used
/// to lose the photo for good.
void showUndoDelete(
  ScaffoldMessengerState messenger,
  ScanStore store,
  List<ScanRecord> gone,
  String message,
  String undoLabel,
) {
  if (gone.isEmpty) return;
  messenger.hideCurrentSnackBar();
  messenger
      .showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 6),
          // A SnackBar with an action stays until tapped unless told not to;
          // the photos are only deleted once it goes, so it must go.
          persist: false,
          action: SnackBarAction(
            label: undoLabel,
            onPressed: () => store.restore(gone),
          ),
        ),
      )
      .closed
      .then((SnackBarClosedReason reason) async {
        if (reason == SnackBarClosedReason.action) return;
        await store.dropPhotosOf(gone);
        for (final ScanRecord r in gone) {
          await RescanReminders.cancel(r.id);
        }
      });
}
