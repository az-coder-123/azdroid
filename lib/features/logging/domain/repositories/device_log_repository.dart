import 'package:desk_droid/features/logging/domain/entities/device_log_entry.dart';
import 'package:desk_droid/features/logging/domain/entities/log_file_recording_status.dart';

/// Contract for managing Android real-time logcat streaming and local recording.
abstract class DeviceLogRepository {
  /// Spawns or connects to the active ADB logcat process and streams batches
  /// of parsed entries.
  Stream<List<DeviceLogEntry>> streamLogs(String deviceSerial);

  /// Clears the log buffer on the physical Android device (`adb logcat -c`).
  Future<void> clearDeviceBuffer(String deviceSerial);

  /// Starts real-time streaming of incoming logs directly to a local file.
  Future<String> startRecordingToFile({
    required String deviceSerial,
    String? customDirectory,
    String? customFilePath,
  });

  /// Stops disk recording and flushes pending buffers.
  Future<LogFileRecordingStatus> stopRecordingToFile();

  /// Returns current file recording telemetry.
  LogFileRecordingStatus get recordingStatus;

  /// Exports an in-memory snapshot of log entries to a local file.
  Future<String> exportLogsToFile({
    required List<DeviceLogEntry> entries,
    required String destinationPath,
  });

  /// Stops any running logcat background streaming processes.
  void stopStream();

  /// Releases resources, timers, and stream controllers.
  void dispose();
}
