import 'dart:async';
import 'dart:io';

import 'package:wifi_desk/core/services/app_logger.dart';
import 'package:wifi_desk/features/logging/data/datasources/log_file_recorder.dart';
import 'package:wifi_desk/features/logging/data/datasources/logcat_stream_datasource.dart';
import 'package:wifi_desk/features/logging/data/models/logcat_threadtime_parser.dart';
import 'package:wifi_desk/features/logging/domain/entities/device_log_entry.dart';
import 'package:wifi_desk/features/logging/domain/entities/log_file_recording_status.dart';
import 'package:wifi_desk/features/logging/domain/repositories/device_log_repository.dart';

/// Implementation of [DeviceLogRepository] providing batched logcat streaming,
/// bounded in-memory caching, and non-blocking real-time file recording.
class DeviceLogRepositoryImpl implements DeviceLogRepository {
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

  final List<DeviceLogEntry> _pendingBatch = [];
  final List<DeviceLogEntry> _ringBuffer = [];
  int _monotonicIdCounter = 0;

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

            // 2. Parse entry and enqueue to pending batch
            _monotonicIdCounter++;
            final entry = _parser.parseLine(rawLine, _monotonicIdCounter);
            _pendingBatch.add(entry);

            // Maintain in-memory ring buffer
            _ringBuffer.add(entry);
            if (_ringBuffer.length > maxBufferEntries) {
              _ringBuffer.removeRange(0, _ringBuffer.length - maxBufferEntries);
            }

            // If batch grows large rapidly, flush early to prevent memory pressure
            if (_pendingBatch.length >= 200) {
              _flushPendingBatch();
            }
          },
          onError: (Object error) {
            if (!controller.isClosed) controller.addError(error);
          },
          onDone: () {
            _flushPendingBatch();
            if (!controller.isClosed) controller.close();
          },
        );

    return controller.stream;
  }

  void _flushPendingBatch() {
    if (_pendingBatch.isEmpty ||
        _batchController == null ||
        _batchController!.isClosed) {
      return;
    }

    final batchToEmit = List<DeviceLogEntry>.from(_pendingBatch);
    _pendingBatch.clear();
    _batchController!.add(batchToEmit);
  }

  @override
  Future<void> clearDeviceBuffer(String deviceSerial) async {
    _ringBuffer.clear();
    _pendingBatch.clear();
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
        '=== WifiDesk Exported Logs: ${DateTime.now().toIso8601String()} ===',
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
    _pendingBatch.clear();
  }
}
