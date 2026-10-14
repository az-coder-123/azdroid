import 'dart:convert';
import 'dart:io';

import 'package:wifi_desk/core/services/app_logger.dart';
import 'package:wifi_desk/features/logging/domain/entities/log_file_recording_status.dart';

/// Manages asynchronous, non-blocking disk persistence for active logcat streams.
class LogFileRecorder {
  LogFileRecorder();

  IOSink? _activeSink;
  String? _activeFilePath;
  int _bytesWritten = 0;
  int _linesWritten = 0;

  /// Returns current recording telemetry.
  LogFileRecordingStatus get status => LogFileRecordingStatus(
    isRecording: _activeSink != null,
    targetFilePath: _activeFilePath,
    bytesWritten: _bytesWritten,
    linesWritten: _linesWritten,
  );

  /// Generates a sensible default path in the user's Downloads directory.
  String generateDefaultLogFilePath(String deviceSerial) {
    final home = Platform.environment['HOME'] ?? '';
    final sanitizedSerial = deviceSerial.replaceAll(
      RegExp(r'[^a-zA-Z0-9_-]'),
      '_',
    );
    final now = DateTime.now();
    final timestamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';

    final baseDir = home.isNotEmpty
        ? '$home/Downloads/wifidesk_logs'
        : 'wifidesk_logs';
    return '$baseDir/logcat_${sanitizedSerial}_$timestamp.log';
  }

  /// Begins appending lines to the given file path.
  Future<String> startRecording(String destinationPath) async {
    await stopRecording();

    try {
      final file = File(destinationPath);
      final parent = file.parent;
      if (!await parent.exists()) {
        await parent.create(recursive: true);
      }

      _activeSink = file.openWrite(
        mode: FileMode.writeOnlyAppend,
        encoding: utf8,
      );
      _activeFilePath = destinationPath;
      _bytesWritten = 0;
      _linesWritten = 0;

      // Header marker
      final header =
          '=== WifiDesk Real-time Logcat Session Started: ${DateTime.now().toIso8601String()} ===\n';
      _activeSink!.write(header);
      _bytesWritten += utf8.encode(header).length;

      AppLogger.info('Log recording started at: $destinationPath');
      return destinationPath;
    } catch (e, stack) {
      AppLogger.warning(
        'Failed to open log file for recording: $e',
        error: e,
        stackTrace: stack,
      );
      await stopRecording();
      rethrow;
    }
  }

  /// Appends a raw logcat line to the active file sink.
  void writeLine(String line) {
    final sink = _activeSink;
    if (sink == null) return;

    try {
      sink.writeln(line);
      _linesWritten++;
      _bytesWritten += utf8.encode(line).length + 1; // +1 for newline
    } catch (e) {
      AppLogger.debug('Error appending line to log sink: $e');
    }
  }

  /// Flushes and closes the active file stream.
  Future<LogFileRecordingStatus> stopRecording() async {
    final sink = _activeSink;
    final lastStatus = status;

    if (sink != null) {
      try {
        sink.writeln(
          '=== WifiDesk Logcat Session Ended: ${DateTime.now().toIso8601String()} ===',
        );
        await sink.flush();
        await sink.close();
      } catch (e) {
        AppLogger.debug('Error closing log file sink: $e');
      } finally {
        _activeSink = null;
        _activeFilePath = null;
        _bytesWritten = 0;
        _linesWritten = 0;
      }
    }

    return lastStatus.copyWith(isRecording: false);
  }
}
