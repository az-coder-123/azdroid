import 'package:desk_droid/features/logging/domain/repositories/device_log_repository.dart';
import 'package:desk_droid/features/logging/presentation/cubit/device_log_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Mixin encapsulating log buffer clearing, file recording, and export persistence
/// for [Cubit<DeviceLogState>].
mixin DeviceLogPersistenceMixin on Cubit<DeviceLogState> {
  DeviceLogRepository get repository;

  /// Clears in-memory logs from the console.
  void clearConsole() {
    final current = state;
    if (current is! DeviceLogStreaming) return;
    emit(current.copyWith(allEntries: const [], filteredEntries: const []));
  }

  /// Clears log buffer on the physical Android device.
  Future<void> clearDeviceBuffer() async {
    final current = state;
    if (current is! DeviceLogStreaming) return;
    clearConsole();
    await repository.clearDeviceBuffer(current.deviceSerial);
    emit(
      current.copyWith(
        allEntries: const [],
        filteredEntries: const [],
        feedbackMessage: () => 'Device logcat buffer cleared',
      ),
    );
  }

  /// Toggles real-time streaming to a local `.log` file.
  Future<void> toggleFileRecording({
    String? customDirectory,
    String? customFilePath,
  }) async {
    final current = state;
    if (current is! DeviceLogStreaming) return;

    if (current.recordingStatus.isRecording) {
      final finalStatus = await repository.stopRecordingToFile();
      emit(
        current.copyWith(
          recordingStatus: finalStatus,
          feedbackMessage: () => 'Log saved to: ${finalStatus.targetFilePath}',
        ),
      );
    } else {
      final savedPath = await repository.startRecordingToFile(
        deviceSerial: current.deviceSerial,
        customDirectory: customDirectory,
        customFilePath: customFilePath,
      );
      emit(
        current.copyWith(
          recordingStatus: repository.recordingStatus,
          feedbackMessage: () => 'Recording logs to: $savedPath',
        ),
      );
    }
  }

  /// Exports current in-memory filtered logs to a file.
  ///
  /// Uses the repository's default snapshot path when [destinationPath] is
  /// omitted.
  Future<void> exportLogs({String? destinationPath}) async {
    final current = state;
    if (current is! DeviceLogStreaming) return;
    final target =
        destinationPath ?? repository.defaultSnapshotPath(current.deviceSerial);

    final targetEntries = current.filteredEntries.isNotEmpty
        ? current.filteredEntries
        : current.allEntries;

    await repository.exportLogsToFile(
      entries: targetEntries,
      destinationPath: target,
    );
    emit(
      current.copyWith(
        feedbackMessage: () =>
            'Exported ${targetEntries.length} logs to $target',
      ),
    );
  }

  /// Synchronizes file recording telemetry into active streaming state.
  void syncRecordingTelemetry() {
    final current = state;
    if (current is! DeviceLogStreaming) return;
    if (current.recordingStatus.isRecording) {
      emit(current.copyWith(recordingStatus: repository.recordingStatus));
    }
  }
}
