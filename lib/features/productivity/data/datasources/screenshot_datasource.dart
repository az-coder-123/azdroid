import 'dart:io';

import 'package:wifi_desk/core/services/adb_service.dart';
import 'package:wifi_desk/core/services/app_logger.dart';
import 'package:wifi_desk/core/services/process_executor.dart';
import 'package:wifi_desk/features/productivity/domain/entities/screenshot_entity.dart';

/// Data source interface for capturing raw device screenshots.
abstract class ScreenshotDatasource {
  Future<ScreenshotEntity?> captureScreenshot({
    required String deviceSerial,
    String? customSaveDirectory,
  });
}

/// Implementation using ADB `exec-out screencap -p` and macOS system clipboard integration.
class ScreenshotDatasourceImpl implements ScreenshotDatasource {
  ScreenshotDatasourceImpl({
    AdbService? adbService,
    ProcessExecutor? processExecutor,
  }) : _adbService = adbService ?? AdbService(),
       _executor = processExecutor ?? const DefaultProcessExecutor();

  final AdbService _adbService;
  final ProcessExecutor _executor;

  @override
  Future<ScreenshotEntity?> captureScreenshot({
    required String deviceSerial,
    String? customSaveDirectory,
  }) async {
    final adb = await _adbService.resolveAdbPath();
    if (adb == null) {
      throw const SocketException('ADB executable not available on host');
    }

    // Determine target save directory (defaulting to macOS ~/Downloads)
    final home = Platform.environment['HOME'] ?? Directory.systemTemp.path;
    final targetDir = Directory(customSaveDirectory ?? '$home/Downloads');
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final h = now.hour.toString().padLeft(2, '0');
    final min = now.minute.toString().padLeft(2, '0');
    final s = now.second.toString().padLeft(2, '0');
    final fileName = 'WifiDesk_Screenshot_$y$m${d}_$h$min$s.png';
    final filePath = '${targetDir.path}/$fileName';
    final targetFile = File(filePath);

    try {
      final process = await Process.start(adb, [
        '-s',
        deviceSerial,
        'exec-out',
        'screencap',
        '-p',
      ]);

      final fileSink = targetFile.openWrite();
      await process.stdout.pipe(fileSink);
      final exitCode = await process.exitCode;

      if (exitCode != 0 || !await targetFile.exists()) {
        throw ProcessException(
          adb,
          ['-s', deviceSerial, 'exec-out', 'screencap', '-p'],
          'Failed to capture screenshot from device',
          exitCode,
        );
      }

      final fileLength = await targetFile.length();
      if (fileLength == 0) {
        await targetFile.delete();
        throw const FormatException('Captured screenshot produced 0 bytes');
      }

      // Copy PNG directly to macOS system clipboard
      var copiedToClipboard = false;
      if (Platform.isMacOS) {
        copiedToClipboard = await _copyImageToMacClipboard(filePath);
      }

      AppLogger.info(
        'Screenshot captured: $filePath ($fileLength bytes, clipboard: $copiedToClipboard)',
      );

      return ScreenshotEntity(
        filePath: filePath,
        fileName: fileName,
        fileSizeBytes: fileLength,
        capturedAt: now,
        copiedToClipboard: copiedToClipboard,
      );
    } catch (e, stack) {
      AppLogger.warning(
        'Failed to take screenshot for $deviceSerial',
        error: e,
        stackTrace: stack,
      );
      if (await targetFile.exists() && await targetFile.length() == 0) {
        await targetFile.delete();
      }
      rethrow;
    }
  }

  Future<bool> _copyImageToMacClipboard(String pngPath) async {
    try {
      final escapedPath = pngPath.replaceAll('"', r'\"');
      final script =
          'set the clipboard to (read (POSIX file "$escapedPath") as «class PNGf»)';
      final res = await _executor.run('/usr/bin/osascript', [
        '-e',
        script,
      ], timeout: const Duration(seconds: 3));
      return res.exitCode == 0;
    } catch (e) {
      AppLogger.debug('Clipboard copy failed: $e');
      return false;
    }
  }
}
