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
    this.selectedEntry,
    this.bookmarkedIds = const {},
    this.softWrap = false,
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

  /// Currently selected entry for inspection in the detail drawer.
  final DeviceLogEntry? selectedEntry;

  /// Set of entry IDs bookmarked/starred by the user.
  final Set<int> bookmarkedIds;

  /// Whether log messages wrap to multiple lines or remain single-line.
  final bool softWrap;

  /// Whether real-time list updates are currently paused.
  final bool isPaused;

  /// Whether console viewport should auto-scroll to the newest entry.
  final bool autoScroll;

  /// Ephemeral feedback toast/banner message.
  final String? feedbackMessage;

  /// Map of unique non-empty tags present in [allEntries] with their line counts,
  /// sorted by frequency descending.
  Map<String, int> get tagCounts {
    final counts = <String, int>{};
    for (final e in allEntries) {
      final t = e.tag.trim();
      if (t.isNotEmpty) {
        counts[t] = (counts[t] ?? 0) + 1;
      }
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted);
  }

  /// Map of unique PIDs present in [allEntries] with their line counts,
  /// sorted by frequency descending.
  Map<int, int> get pidCounts {
    final counts = <int, int>{};
    for (final e in allEntries) {
      if (e.pid > 0) {
        counts[e.pid] = (counts[e.pid] ?? 0) + 1;
      }
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted);
  }

  /// Map associating each PID with its most frequently associated Tag/module.
  Map<int, String> get pidPrimaryTags {
    final pidTagCounts = <int, Map<String, int>>{};
    for (final e in allEntries) {
      if (e.pid <= 0 || e.tag.trim().isEmpty) continue;
      final tags = pidTagCounts.putIfAbsent(e.pid, () => <String, int>{});
      tags[e.tag] = (tags[e.tag] ?? 0) + 1;
    }
    final result = <int, String>{};
    for (final entry in pidTagCounts.entries) {
      final bestTag = entry.value.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;
      result[entry.key] = bestTag;
    }
    return result;
  }

  DeviceLogStreaming copyWith({
    String? deviceSerial,
    List<DeviceLogEntry>? allEntries,
    List<DeviceLogEntry>? filteredEntries,
    LogFilterCriteria? filter,
    LogFileRecordingStatus? recordingStatus,
    bool? isPaused,
    bool? autoScroll,
    DeviceLogEntry? Function()? selectedEntry,
    Set<int>? bookmarkedIds,
    bool? softWrap,
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
      selectedEntry: selectedEntry != null
          ? selectedEntry()
          : this.selectedEntry,
      bookmarkedIds: bookmarkedIds ?? this.bookmarkedIds,
      softWrap: softWrap ?? this.softWrap,
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
    selectedEntry,
    bookmarkedIds,
    softWrap,
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
