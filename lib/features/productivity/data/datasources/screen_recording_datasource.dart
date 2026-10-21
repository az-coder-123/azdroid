import 'dart:io';

import 'package:desk_droid/core/platform/host_paths.dart';
import 'package:desk_droid/core/services/adb_service.dart';
import 'package:desk_droid/core/services/app_logger.dart';
import 'package:desk_droid/core/services/process_executor.dart';
import 'package:desk_droid/features/productivity/domain/entities/screen_recording_entity.dart';

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
  /// Max wait for `screenrecord` to finalize the MP4 after SIGINT.
  static const Duration _finalizeTimeout = Duration(seconds: 4);

  /// Wait used when no process handle is available to await.
  static const Duration _finalizeFallbackDelay = Duration(seconds: 1);

  ScreenRecordingDatasourceImpl({
    AdbService? adbService,
    ProcessExecutor? processExecutor,
    HostPaths? hostPaths,
  }) : _adbService = adbService ?? AdbService(),
       _executor = processExecutor ?? const DefaultProcessExecutor(),
       _paths = hostPaths ?? SystemHostPaths();

  final AdbService _adbService;
  final ProcessExecutor _executor;
  final HostPaths _paths;
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
    final remotePath = '/sdcard/azdroid_rec_$ts.mp4';
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

    // Gracefully interrupt screenrecord so Android finalizes the MP4 moov atom
    await _interruptRemoteRecording(adb, deviceSerial);

    // Wait for the active recording process to exit cleanly on its own.
    // Screenrecord requires ~0.5s to write MP4 track headers and sample tables.
    if (_activeRecordingProcess != null) {
      try {
        await _activeRecordingProcess!.exitCode.timeout(_finalizeTimeout);
      } catch (e) {
        AppLogger.warning('Recording process exit timeout: $e');
        _activeRecordingProcess?.kill(ProcessSignal.sigint);
      }
      _activeRecordingProcess = null;
    } else {
      await Future<void>.delayed(_finalizeFallbackDelay);
    }

    // Determine target save destination on the host
    final targetDir = Directory(
      customSaveDirectory ?? _paths.downloadsDirectory,
    );
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
    final fileName = 'Azdroid_Recording_$y$m${d}_$h$min$s.mp4';
    final filePath = _paths.context.join(targetDir.path, fileName);

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
      final pidResult = await _executor.run(adb, [
        '-s',
        serial,
        'shell',
        'pidof',
        'screenrecord',
      ]);
      final pid = pidResult.stdout.toString().trim();
      if (pid.isNotEmpty) {
        await _executor.run(adb, ['-s', serial, 'shell', 'kill', '-2', pid]);
      } else {
        await _executor.run(adb, [
          '-s',
          serial,
          'shell',
          'pkill',
          '-2',
          'screenrecord',
        ]);
      }
    } catch (e) {
      AppLogger.debug('Interrupting screenrecord produced exception: $e');
    }
  }
}
