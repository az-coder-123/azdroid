import 'dart:async';
import 'dart:io';

import 'package:desk_droid/core/services/app_logger.dart';
import 'package:desk_droid/features/logging/data/datasources/log_file_recorder.dart';
import 'package:desk_droid/features/logging/data/datasources/logcat_stream_datasource.dart';
import 'package:desk_droid/features/logging/data/models/logcat_threadtime_parser.dart';
import 'package:desk_droid/features/logging/domain/entities/device_log_entry.dart';
import 'package:desk_droid/features/logging/domain/entities/log_file_recording_status.dart';
import 'package:desk_droid/features/logging/domain/repositories/device_log_repository.dart';

/// Implementation of [DeviceLogRepository] providing batched logcat streaming,
/// bounded in-memory caching, and non-blocking real-time file recording.
class DeviceLogRepositoryImpl implements DeviceLogRepository {
  /// Backlog size that triggers an immediate flush instead of waiting.
  static const int _maxPendingLines = 200;

  DeviceLogRepositoryImpl({
    LogcatStreamDatasource? datasource,
    LogFileRecorder? fileRecorder,
    LogcatThreadtimeParser? parser,
    this.batchInterval = const Duration(milliseconds: 100),
    this.maxBufferEntries = 5000,
  }) : _datasource = datasource ?? LogcatStreamDatasource(),
       _fileRecorder = fileRecorder ?? LogFileRecorder(),
       _parser = parser ?? const LogcatThreadtimeParser();

  final LogcatStreamDatasource _datasource;
  final LogFileRecorder _fileRecorder;
  final LogcatThreadtimeParser _parser;
  final Duration batchInterval;
  final int maxBufferEntries;

  StreamSubscription<String>? _rawSubscription;
  Timer? _batchTimer;
  StreamController<List<DeviceLogEntry>>? _batchController;

  final List<String> _pendingRawLines = [];
  final List<DeviceLogEntry> _ringBuffer = [];
  int _monotonicIdCounter = 0;
  bool _isFlushing = false;

  @override
  LogFileRecordingStatus get recordingStatus => _fileRecorder.status;

  @override
  Stream<List<DeviceLogEntry>> streamLogs(String deviceSerial) {
    stopStream();

    final controller = StreamController<List<DeviceLogEntry>>.broadcast();
    _batchController = controller;

    _batchTimer = Timer.periodic(batchInterval, (_) => _flushPendingBatch());

    _rawSubscription = _datasource
        .startLogcatStream(deviceSerial)
        .listen(
          (rawLine) {
            // 1. Asynchronous write to local file if recording is active
            _fileRecorder.writeLine(rawLine);

            // 2. Enqueue raw line for concurrent background parsing
            _pendingRawLines.add(rawLine);

            // If batch grows large rapidly, flush early to prevent memory pressure
            if (_pendingRawLines.length >= _maxPendingLines) {
              _flushPendingBatch();
            }
          },
          onError: (Object error) {
            if (!controller.isClosed) controller.addError(error);
          },
          onDone: () async {
            await _flushPendingBatch();
            if (!controller.isClosed) unawaited(controller.close());
          },
        );

    return controller.stream;
  }

  Future<void> _flushPendingBatch() async {
    if (_pendingRawLines.isEmpty ||
        _batchController == null ||
        _batchController!.isClosed ||
        _isFlushing) {
      return;
    }

    _isFlushing = true;
    final linesToProcess = List<String>.from(_pendingRawLines);
    _pendingRawLines.clear();

    final startingId = _monotonicIdCounter + 1;
    _monotonicIdCounter += linesToProcess.length;

    try {
      final parsedEntries = await _parser.parseBatchAsync(
        linesToProcess,
        startingId,
      );

      // Maintain in-memory ring buffer
      _ringBuffer.addAll(parsedEntries);
      if (_ringBuffer.length > maxBufferEntries) {
        _ringBuffer.removeRange(0, _ringBuffer.length - maxBufferEntries);
      }

      if (_batchController != null && !_batchController!.isClosed) {
        _batchController!.add(parsedEntries);
      }
    } catch (e, stack) {
      AppLogger.warning(
        'Logcat batch parsing failed: $e',
        error: e,
        stackTrace: stack,
      );
    } finally {
      _isFlushing = false;
      if (_pendingRawLines.length >= _maxPendingLines) {
        // Drain the backlog without blocking the caller of this flush.
        unawaited(_flushPendingBatch());
      }
    }
  }

  @override
  Future<void> clearDeviceBuffer(String deviceSerial) async {
    _ringBuffer.clear();
    _pendingRawLines.clear();
    await _datasource.clearLogcat(deviceSerial);
  }

  @override
  Future<String> startRecordingToFile({
    required String deviceSerial,
    String? customDirectory,
    String? customFilePath,
  }) async {
    final destination =
        customFilePath ??
        (customDirectory != null
            ? '$customDirectory/logcat_${deviceSerial.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}_${DateTime.now().millisecondsSinceEpoch}.log'
            : _fileRecorder.generateDefaultLogFilePath(deviceSerial));

    return _fileRecorder.startRecording(destination);
  }

  @override
  Future<LogFileRecordingStatus> stopRecordingToFile() =>
      _fileRecorder.stopRecording();

  @override
  Future<String> exportLogsToFile({
    required List<DeviceLogEntry> entries,
    required String destinationPath,
  }) async {
    try {
      final file = File(destinationPath);
      final parent = file.parent;
      if (!await parent.exists()) {
        await parent.create(recursive: true);
      }

      final buffer = StringBuffer();
      buffer.writeln(
        '=== DeskDroid Exported Logs: ${DateTime.now().toIso8601String()} ===',
      );
      buffer.writeln('Total Entries: ${entries.length}\n');
      for (final entry in entries) {
        buffer.writeln(entry.rawLine);
      }

      await file.writeAsString(buffer.toString());
      AppLogger.info(
        'Exported ${entries.length} log entries to $destinationPath',
      );
      return destinationPath;
    } catch (e, stack) {
      AppLogger.warning(
        'Failed to export logs: $e',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  @override
  void stopStream() {
    _batchTimer?.cancel();
    _batchTimer = null;

    _rawSubscription?.cancel();
    _rawSubscription = null;

    _datasource.stop();

    if (_batchController != null && !_batchController!.isClosed) {
      _batchController!.close();
      _batchController = null;
    }
  }

  @override
  void dispose() {
    stopStream();
    _fileRecorder.stopRecording();
    _ringBuffer.clear();
    _pendingRawLines.clear();
  }
}
