import 'dart:io';

import 'package:desk_droid/core/platform/host_paths.dart';
import 'package:desk_droid/core/platform/image_clipboard/image_clipboard.dart';
import 'package:desk_droid/core/services/adb_service.dart';
import 'package:desk_droid/core/services/app_logger.dart';
import 'package:desk_droid/features/productivity/data/utils/image_crop_util.dart';
import 'package:desk_droid/features/productivity/domain/entities/screenshot_destination.dart';
import 'package:desk_droid/features/productivity/domain/entities/screenshot_entity.dart';
import 'package:flutter/material.dart';

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
  /// Upper bound for the AppleScript that copies a PNG to the pasteboard.
  ScreenshotDatasourceImpl({
    AdbService? adbService,
    HostPaths? hostPaths,
    required this._imageClipboard,
  }) : _adbService = adbService ?? AdbService(),
       _paths = hostPaths ?? SystemHostPaths();

  final AdbService _adbService;
  final HostPaths _paths;
  final ImageClipboard _imageClipboard;

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
    final targetDir = isClipboardOnly
        ? Directory.systemTemp
        : Directory(customSaveDirectory ?? _paths.downloadsDirectory);
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
    final filePath = _paths.context.join(targetDir.path, fileName);
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

      // Copy PNG to the host clipboard if required
      final copiedToClipboard =
          shouldCopyToClipboard && await _imageClipboard.copyPng(filePath);

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
}
