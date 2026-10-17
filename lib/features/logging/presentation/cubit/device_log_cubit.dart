import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:desk_droid/core/services/app_logger.dart';
import 'package:desk_droid/features/logging/domain/entities/device_log_entry.dart';
import 'package:desk_droid/features/logging/domain/entities/log_filter_criteria.dart';
import 'package:desk_droid/features/logging/domain/repositories/device_log_repository.dart';
import 'package:desk_droid/features/logging/presentation/cubit/device_log_filter_mixin.dart';
import 'package:desk_droid/features/logging/presentation/cubit/device_log_persistence_mixin.dart';
import 'package:desk_droid/features/logging/presentation/cubit/device_log_state.dart';

/// Cubit managing real-time Android logcat stream ingestion, viewport pause states,
/// and log line selection.
class DeviceLogCubit extends Cubit<DeviceLogState>
    with DeviceLogFilterMixin, DeviceLogPersistenceMixin {
  DeviceLogCubit({required this.repository, this.maxBufferEntries = 5000})
    : super(const DeviceLogInitial());

  @override
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
      (_) => syncRecordingTelemetry(),
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

    final matchingNew = newBatch.where(
      (e) => current.filter.matches(e, bookmarkedIds: current.bookmarkedIds),
    );
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
          .where(
            (e) =>
                current.filter.matches(e, bookmarkedIds: current.bookmarkedIds),
          )
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

  /// Toggles line wrapping in the log console table.
  void toggleSoftWrap() {
    final current = state;
    if (current is! DeviceLogStreaming) return;
    emit(current.copyWith(softWrap: !current.softWrap));
  }

  /// Selects or deselects an entry for inspection in the detail drawer.
  void selectEntry(DeviceLogEntry? entry) {
    final current = state;
    if (current is! DeviceLogStreaming) return;
    if (current.selectedEntry == entry) {
      emit(current.copyWith(selectedEntry: () => null));
    } else {
      emit(current.copyWith(selectedEntry: () => entry));
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
