import 'package:equatable/equatable.dart';
import 'package:wifi_desk/features/logging/domain/entities/device_log_entry.dart';
import 'package:wifi_desk/features/logging/domain/entities/log_file_recording_status.dart';
import 'package:wifi_desk/features/logging/domain/entities/log_filter_criteria.dart';

/// Base state for device real-time logcat streaming.
abstract class DeviceLogState extends Equatable {
  const DeviceLogState();

  @override
  List<Object?> get props => [];
}

/// Initial inactive state.
class DeviceLogInitial extends DeviceLogState {
  const DeviceLogInitial();
}

/// Active streaming state containing visible logs, active filters, and recording telemetry.
class DeviceLogStreaming extends DeviceLogState {
  const DeviceLogStreaming({
    required this.deviceSerial,
    required this.allEntries,
    required this.filteredEntries,
    required this.filter,
    required this.recordingStatus,
    this.isPaused = false,
    this.autoScroll = true,
    this.feedbackMessage,
  });

  /// Serial or IP address of the streamed device.
  final String deviceSerial;

  /// Bounded in-memory buffer of all received log entries.
  final List<DeviceLogEntry> allEntries;

  /// Subset of entries matching [filter].
  final List<DeviceLogEntry> filteredEntries;

  /// Active filter criteria.
  final LogFilterCriteria filter;

  /// Local disk recording status.
  final LogFileRecordingStatus recordingStatus;

  /// Whether real-time list updates are currently paused.
  final bool isPaused;

  /// Whether console viewport should auto-scroll to the newest entry.
  final bool autoScroll;

  /// Ephemeral feedback toast/banner message.
  final String? feedbackMessage;

  DeviceLogStreaming copyWith({
    String? deviceSerial,
    List<DeviceLogEntry>? allEntries,
    List<DeviceLogEntry>? filteredEntries,
    LogFilterCriteria? filter,
    LogFileRecordingStatus? recordingStatus,
    bool? isPaused,
    bool? autoScroll,
    String? Function()? feedbackMessage,
  }) {
    return DeviceLogStreaming(
      deviceSerial: deviceSerial ?? this.deviceSerial,
      allEntries: allEntries ?? this.allEntries,
      filteredEntries: filteredEntries ?? this.filteredEntries,
      filter: filter ?? this.filter,
      recordingStatus: recordingStatus ?? this.recordingStatus,
      isPaused: isPaused ?? this.isPaused,
      autoScroll: autoScroll ?? this.autoScroll,
      feedbackMessage: feedbackMessage != null
          ? feedbackMessage()
          : this.feedbackMessage,
    );
  }

  @override
  List<Object?> get props => [
    deviceSerial,
    allEntries.length,
    filteredEntries.length,
    filter,
    recordingStatus,
    isPaused,
    autoScroll,
    feedbackMessage,
  ];
}

/// Failure state when ADB logcat process terminates abnormally.
class DeviceLogError extends DeviceLogState {
  const DeviceLogError({required this.message, required this.deviceSerial});

  final String message;
  final String deviceSerial;

  @override
  List<Object?> get props => [message, deviceSerial];
}
