import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Where scan photos live for as long as their scan does.
///
/// The camera and the gallery picker both hand back a file in the app's
/// *cache* folder, and Android empties that folder whenever it wants the
/// space — and on every reinstall. Scans kept a path to that file, so a few
/// days later the photo on the scan's details page, the colour check and the
/// focus map all quietly broke. Each photo is now copied into the app's own
/// documents folder when the scan is saved, and removed with the scan.

Future<Directory> _folder() async {
  final Directory docs = await getApplicationDocumentsDirectory();
  final Directory dir = Directory('${docs.path}/scans');
  if (!await dir.exists()) await dir.create(recursive: true);
  return dir;
}

/// Copies [tempPath] into permanent storage and returns the new path. Falls
/// back to the original path if copying fails, so a scan is never lost over
/// its photo.
Future<String> keepPhoto(String tempPath) async {
  if (kIsWeb || tempPath.isEmpty) return tempPath;
  try {
    final Directory dir = await _folder();
    final String dot = tempPath.lastIndexOf('.') > tempPath.lastIndexOf('/')
        ? tempPath.substring(tempPath.lastIndexOf('.'))
        : '.jpg';
    final String dest =
        '${dir.path}/${DateTime.now().millisecondsSinceEpoch}$dot';
    await File(tempPath).copy(dest);
    return dest;
  } catch (_) {
    return tempPath;
  }
}

/// Deletes a kept photo. Only files inside the scans folder are touched.
Future<void> dropPhoto(String path) async {
  if (kIsWeb || path.isEmpty) return;
  try {
    final Directory dir = await _folder();
    if (!path.startsWith(dir.path)) return;
    final File f = File(path);
    if (await f.exists()) await f.delete();
  } catch (_) {
    // A leftover file costs a little space; not worth failing a delete over.
  }
}

/// Deletes every kept photo — used by "Delete all scans".
Future<void> dropAllPhotos() async {
  if (kIsWeb) return;
  try {
    final Directory dir = await _folder();
    await for (final FileSystemEntity e in dir.list()) {
      if (e is File) await e.delete();
    }
  } catch (_) {}
}
