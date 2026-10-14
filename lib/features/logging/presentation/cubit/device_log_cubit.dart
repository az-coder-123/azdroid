import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wifi_desk/core/services/app_logger.dart';
import 'package:wifi_desk/features/logging/domain/entities/device_log_entry.dart';
import 'package:wifi_desk/features/logging/domain/entities/log_filter_criteria.dart';
import 'package:wifi_desk/features/logging/domain/entities/log_level.dart';
import 'package:wifi_desk/features/logging/domain/repositories/device_log_repository.dart';
import 'package:wifi_desk/features/logging/presentation/cubit/device_log_state.dart';

/// Cubit managing real-time Android logcat stream ingestion, multi-tier filtering,
/// disk persistence, and viewport pause states.
class DeviceLogCubit extends Cubit<DeviceLogState> {
  DeviceLogCubit({required this.repository, this.maxBufferEntries = 5000})
    : super(const DeviceLogInitial());

  final DeviceLogRepository repository;
  final int maxBufferEntries;

  StreamSubscription<List<DeviceLogEntry>>? _streamSubscription;
  Timer? _recordingTelemetryTimer;

  /// Starts listening to real-time logcat output from [deviceSerial].
  void startLogging(String deviceSerial) {
    _streamSubscription?.cancel();
    _recordingTelemetryTimer?.cancel();

    emit(
      DeviceLogStreaming(
        deviceSerial: deviceSerial,
        allEntries: const [],
        filteredEntries: const [],
        filter: const LogFilterCriteria(),
        recordingStatus: repository.recordingStatus,
        isPaused: false,
        autoScroll: true,
      ),
    );

    _recordingTelemetryTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _syncRecordingTelemetry(),
    );

    _streamSubscription = repository
        .streamLogs(deviceSerial)
        .listen(
          _handleIncomingBatch,
          onError: (Object error) {
            AppLogger.warning('Logcat stream error: $error');
            emit(
              DeviceLogError(
                message: error.toString(),
                deviceSerial: deviceSerial,
              ),
            );
          },
        );
  }

  void _handleIncomingBatch(List<DeviceLogEntry> newBatch) {
    final current = state;
    if (current is! DeviceLogStreaming) return;

    final updatedAll = _appendBounded(current.allEntries, newBatch);

    if (current.isPaused) {
      emit(
        current.copyWith(
          allEntries: updatedAll,
          recordingStatus: repository.recordingStatus,
        ),
      );
      return;
    }

    final matchingNew = newBatch.where((e) => current.filter.matches(e));
    final updatedFiltered = _appendBounded(
      current.filteredEntries,
      matchingNew,
    );

    emit(
      current.copyWith(
        allEntries: updatedAll,
        filteredEntries: updatedFiltered,
        recordingStatus: repository.recordingStatus,
      ),
    );
  }

  List<DeviceLogEntry> _appendBounded(
    List<DeviceLogEntry> base,
    Iterable<DeviceLogEntry> items,
  ) {
    final res = List<DeviceLogEntry>.from(base)..addAll(items);
    if (res.length > maxBufferEntries) {
      res.removeRange(0, res.length - maxBufferEntries);
    }
    return res;
  }

  /// Toggles stream pause state.
  void togglePause() {
    final current = state;
    if (current is! DeviceLogStreaming) return;
    if (current.isPaused) {
      final reFiltered = current.allEntries
          .where(current.filter.matches)
          .toList();
      emit(current.copyWith(isPaused: false, filteredEntries: reFiltered));
    } else {
      emit(current.copyWith(isPaused: true));
    }
  }

  /// Toggles viewport auto-scrolling to bottom.
  void toggleAutoScroll() {
    final current = state;
    if (current is! DeviceLogStreaming) return;
    emit(current.copyWith(autoScroll: !current.autoScroll));
  }

  /// Updates active filter criteria and re-evaluates visible logs.
  void updateFilter(LogFilterCriteria newFilter) {
    final current = state;
    if (current is! DeviceLogStreaming) return;
    final filtered = current.allEntries.where(newFilter.matches).toList();
    emit(current.copyWith(filter: newFilter, filteredEntries: filtered));
  }

  /// Toggles a specific severity level.
  void toggleLevel(LogLevel level) {
    final current = state;
    if (current is! DeviceLogStreaming) return;
    final levels = Set<LogLevel>.from(current.filter.selectedLevels);
    levels.contains(level) ? levels.remove(level) : levels.add(level);
    updateFilter(current.filter.copyWith(selectedLevels: levels));
  }

  /// Updates search text query.
  void updateSearch(String query) {
    final current = state;
    if (current is DeviceLogStreaming) {
      updateFilter(current.filter.copyWith(textQuery: query));
    }
  }

  /// Toggles regex evaluation mode.
  void toggleRegex() {
    final current = state;
    if (current is DeviceLogStreaming) {
      updateFilter(current.filter.copyWith(isRegex: !current.filter.isRegex));
    }
  }

  /// Toggles case-sensitivity for search and tags.
  void toggleCaseSensitive() {
    final current = state;
    if (current is DeviceLogStreaming) {
      updateFilter(
        current.filter.copyWith(caseSensitive: !current.filter.caseSensitive),
      );
    }
  }

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
  Future<void> exportLogs({required String destinationPath}) async {
    final current = state;
    if (current is! DeviceLogStreaming) return;

    final targetEntries = current.filteredEntries.isNotEmpty
        ? current.filteredEntries
        : current.allEntries;

    await repository.exportLogsToFile(
      entries: targetEntries,
      destinationPath: destinationPath,
    );
    emit(
      current.copyWith(
        feedbackMessage: () =>
            'Exported ${targetEntries.length} logs to $destinationPath',
      ),
    );
  }

  void _syncRecordingTelemetry() {
    final current = state;
    if (current is! DeviceLogStreaming) return;
    if (current.recordingStatus.isRecording) {
      emit(current.copyWith(recordingStatus: repository.recordingStatus));
    }
  }

  /// Stops logging and releases active sub-processes.
  void stopLogging() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _recordingTelemetryTimer?.cancel();
    _recordingTelemetryTimer = null;
    repository.stopStream();
    if (!isClosed) {
      emit(const DeviceLogInitial());
    }
  }

  @override
  Future<void> close() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _recordingTelemetryTimer?.cancel();
    _recordingTelemetryTimer = null;
    repository.dispose();
    return super.close();
  }
}
