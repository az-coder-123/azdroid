import 'dart:io';

import 'package:wifi_desk/core/services/adb_service.dart';
import 'package:wifi_desk/core/services/app_logger.dart';
import 'package:wifi_desk/core/services/process_executor.dart';
import 'package:wifi_desk/features/productivity/domain/entities/screen_recording_entity.dart';

/// Data source interface for capturing device screen recordings.
abstract class ScreenRecordingDatasource {
  Future<String> startRecording({
    required String deviceSerial,
    int? bitrateBps,
    int? timeLimitSeconds,
  });

  Future<ScreenRecordingEntity?> stopRecording({
    required String deviceSerial,
    required String remoteTempPath,
    required Duration duration,
    String? customSaveDirectory,
  });

  Future<void> cancelRecording({
    required String deviceSerial,
    required String remoteTempPath,
  });
}

/// Implementation using ADB `screenrecord` daemon and pull transfer.
class ScreenRecordingDatasourceImpl implements ScreenRecordingDatasource {
  ScreenRecordingDatasourceImpl({
    AdbService? adbService,
    ProcessExecutor? processExecutor,
  }) : _adbService = adbService ?? AdbService(),
       _executor = processExecutor ?? const DefaultProcessExecutor();

  final AdbService _adbService;
  final ProcessExecutor _executor;
  Process? _activeRecordingProcess;

  @override
  Future<String> startRecording({
    required String deviceSerial,
    int? bitrateBps,
    int? timeLimitSeconds,
  }) async {
    final adb = await _adbService.resolveAdbPath();
    if (adb == null) {
      throw const SocketException('ADB executable not available on host');
    }

    final ts = DateTime.now().millisecondsSinceEpoch;
    final remotePath = '/sdcard/wifidesk_rec_$ts.mp4';
    final bitrate = (bitrateBps ?? 8000000).toString();
    final timeLimit = (timeLimitSeconds ?? 180).toString();

    AppLogger.info('Starting screenrecord on $deviceSerial -> $remotePath');

    _activeRecordingProcess = await Process.start(adb, [
      '-s',
      deviceSerial,
      'shell',
      'screenrecord',
      '--bit-rate',
      bitrate,
      '--time-limit',
      timeLimit,
      remotePath,
    ]);

    return remotePath;
  }

  @override
  Future<ScreenRecordingEntity?> stopRecording({
    required String deviceSerial,
    required String remoteTempPath,
    required Duration duration,
    String? customSaveDirectory,
  }) async {
    final adb = await _adbService.resolveAdbPath();
    if (adb == null) {
      throw const SocketException('ADB executable not available on host');
    }

    // Gracefully interrupt screenrecord so it finalizes the MP4 moov atom
    await _interruptRemoteRecording(adb, deviceSerial);
    _activeRecordingProcess?.kill(ProcessSignal.sigint);
    _activeRecordingProcess = null;

    // Brief delay to allow the device to flush file buffer
    await Future<void>.delayed(const Duration(milliseconds: 800));

    // Determine target save destination on macOS
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
    final fileName = 'WifiDesk_Recording_$y$m${d}_$h$min$s.mp4';
    final filePath = '${targetDir.path}/$fileName';

    try {
      final pullResult = await _executor.run(adb, [
        '-s',
        deviceSerial,
        'pull',
        remoteTempPath,
        filePath,
      ]);

      if (pullResult.exitCode != 0) {
        throw ProcessException(
          adb,
          ['-s', deviceSerial, 'pull', remoteTempPath, filePath],
          pullResult.stderr.toString(),
          pullResult.exitCode,
        );
      }

      final targetFile = File(filePath);
      if (!await targetFile.exists() || await targetFile.length() == 0) {
        throw const FormatException('Pulled video file is empty or corrupted');
      }

      final fileLength = await targetFile.length();
      AppLogger.info(
        'Screen recording successfully saved: $filePath ($fileLength bytes)',
      );

      return ScreenRecordingEntity(
        filePath: filePath,
        fileName: fileName,
        fileSizeBytes: fileLength,
        duration: duration,
        recordedAt: now.subtract(duration),
      );
    } finally {
      // Clean up temporary file from device sdcard
      await _executor.run(adb, [
        '-s',
        deviceSerial,
        'shell',
        'rm',
        '-f',
        remoteTempPath,
      ]);
    }
  }

  @override
  Future<void> cancelRecording({
    required String deviceSerial,
    required String remoteTempPath,
  }) async {
    final adb = await _adbService.resolveAdbPath();
    if (adb == null) return;

    await _interruptRemoteRecording(adb, deviceSerial);
    _activeRecordingProcess?.kill(ProcessSignal.sigkill);
    _activeRecordingProcess = null;

    await _executor.run(adb, [
      '-s',
      deviceSerial,
      'shell',
      'rm',
      '-f',
      remoteTempPath,
    ]);
  }

  Future<void> _interruptRemoteRecording(String adb, String serial) async {
    try {
      await _executor.run(adb, [
        '-s',
        serial,
        'shell',
        r'kill -2 $(pidof screenrecord) 2>/dev/null || killall -2 screenrecord 2>/dev/null',
      ]);
    } catch (e) {
      AppLogger.debug('Interrupting screenrecord produced exception: $e');
    }
  }
}
