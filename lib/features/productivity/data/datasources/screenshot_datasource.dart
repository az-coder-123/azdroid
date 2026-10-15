import 'dart:io';

import 'package:flutter/material.dart';
import 'package:desk_droid/core/services/adb_service.dart';
import 'package:desk_droid/core/services/app_logger.dart';
import 'package:desk_droid/core/services/process_executor.dart';
import 'package:desk_droid/features/productivity/data/utils/image_crop_util.dart';
import 'package:desk_droid/features/productivity/domain/entities/screenshot_destination.dart';
import 'package:desk_droid/features/productivity/domain/entities/screenshot_entity.dart';

/// Data source interface for capturing raw device screenshots.
abstract class ScreenshotDatasource {
  Future<ScreenshotEntity?> captureScreenshot({
    required String deviceSerial,
    String? customSaveDirectory,
    Rect? cropRectNormalized,
    ScreenshotDestination destination = ScreenshotDestination.both,
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
    Rect? cropRectNormalized,
    ScreenshotDestination destination = ScreenshotDestination.both,
  }) async {
    final adb = await _adbService.resolveAdbPath();
    if (adb == null) {
      throw const SocketException('ADB executable not available on host');
    }

    final isClipboardOnly = destination == ScreenshotDestination.clipboard;
    final saveToFile = destination != ScreenshotDestination.clipboard;
    final shouldCopyToClipboard = destination != ScreenshotDestination.file;

    // Determine target save directory
    final home = Platform.environment['HOME'] ?? Directory.systemTemp.path;
    final targetDir = isClipboardOnly
        ? Directory.systemTemp
        : Directory(customSaveDirectory ?? '$home/Downloads');
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
    final fileName = 'DeskDroid_Screenshot_$y$m${d}_$h$min$s.png';
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

      // If user selected a specific area, crop the image
      if (cropRectNormalized != null) {
        final originalBytes = await targetFile.readAsBytes();
        final croppedBytes = await ImageCropUtil.cropPng(
          originalBytes,
          cropRectNormalized,
        );
        await targetFile.writeAsBytes(croppedBytes, flush: true);
      }

      final fileLength = await targetFile.length();
      if (fileLength == 0) {
        await targetFile.delete();
        throw const FormatException('Captured screenshot produced 0 bytes');
      }

      // Copy PNG directly to macOS system clipboard if required
      var copiedToClipboard = false;
      if (shouldCopyToClipboard && Platform.isMacOS) {
        copiedToClipboard = await _copyImageToMacClipboard(filePath);
      }

      // If clipboard-only, remove temporary disk file
      if (isClipboardOnly) {
        await targetFile.delete();
      }

      AppLogger.info(
        'Screenshot captured ($destination): $fileName ($fileLength bytes, saved: $saveToFile, clipboard: $copiedToClipboard)',
      );

      return ScreenshotEntity(
        filePath: saveToFile ? filePath : '',
        fileName: fileName,
        fileSizeBytes: fileLength,
        capturedAt: now,
        copiedToClipboard: copiedToClipboard,
        savedToFile: saveToFile,
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
