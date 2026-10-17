import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:desk_droid/core/services/app_logger.dart';

/// Reads a single entry (for example a launcher icon) from an APK archive.
abstract class ApkEntryReader {
  /// Returns the bytes of [entryPath] inside [apkPath], or `null` when the
  /// entry is missing or the archive cannot be read.
  Future<Uint8List?> readEntry(String apkPath, String entryPath);
}

/// Cross-platform [ApkEntryReader] built on `package:archive`.
///
/// Streams the zip central directory from disk, so large APKs are not loaded
/// into memory; only the requested entry is inflated.
class ZipApkEntryReader implements ApkEntryReader {
  const ZipApkEntryReader();

  @override
  Future<Uint8List?> readEntry(String apkPath, String entryPath) async {
    InputFileStream? input;
    try {
      input = InputFileStream(apkPath);
      final archive = ZipDecoder().decodeStream(input);
      return archive.findFile(entryPath)?.readBytes();
    } on Exception catch (error) {
      AppLogger.debug('Failed to read "$entryPath" from $apkPath: $error');
      return null;
    } finally {
      await input?.close();
    }
  }
}
