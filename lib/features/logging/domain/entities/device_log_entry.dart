import 'package:desk_droid/features/logging/domain/entities/log_level.dart';
import 'package:equatable/equatable.dart';

/// Represents a single parsed Android logcat entry.
class DeviceLogEntry extends Equatable {
  const DeviceLogEntry({
    required this.id,
    required this.timestamp,
    required this.pid,
    required this.tid,
    required this.level,
    required this.tag,
    required this.message,
    required this.rawLine,
  });

  /// Unique monotonic ID within the session for list keys.
  final int id;

  /// Parsed logcat timestamp (month, day, hour, min, sec, millisecond).
  final DateTime timestamp;

  /// Process ID.
  final int pid;

  /// Thread ID.
  final int tid;

  /// Severity level (V, D, I, W, E, F).
  final LogLevel level;

  /// Android Log tag.
  final String tag;

  /// Log body payload.
  final String message;

  /// Original unparsed raw stdout line.
  final String rawLine;

  @override
  List<Object?> get props => [
    id,
    timestamp,
    pid,
    tid,
    level,
    tag,
    message,
    rawLine,
  ];
}
