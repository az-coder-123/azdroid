import 'package:flutter/foundation.dart';
import 'package:desk_droid/features/logging/domain/entities/device_log_entry.dart';
import 'package:desk_droid/features/logging/domain/entities/log_level.dart';

/// Data payload passed to background isolate for concurrent batch parsing.
class LogcatBatchPayload {
  const LogcatBatchPayload({required this.lines, required this.startingId});

  final List<String> lines;
  final int startingId;
}

/// Top-level function executed inside Dart background isolate.
List<DeviceLogEntry> parseLogcatBatchInIsolate(LogcatBatchPayload payload) {
  const parser = LogcatThreadtimeParser();
  return parser.parseLines(payload.lines, payload.startingId);
}

/// Parses raw Android logcat lines (using `-v threadtime` format) into [DeviceLogEntry] instances.
class LogcatThreadtimeParser {
  const LogcatThreadtimeParser();

  // Format: 10-14 10:48:15.836  1299  1421 D BatteryService: Message text...
  static final RegExp _threadtimeRegex = RegExp(
    r'^(\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}\.\d{3})\s+(\d+)\s+(\d+)\s+([VDIWEF])\s+([^:]+?)\s*:\s*(.*)$',
  );

  /// Parses multiple logcat lines sequentially into a list of [DeviceLogEntry].
  List<DeviceLogEntry> parseLines(List<String> lines, int startingId) {
    var currentId = startingId;
    final results = <DeviceLogEntry>[];
    for (final line in lines) {
      results.add(parseLine(line, currentId++));
    }
    return results;
  }

  /// Parses multiple lines asynchronously, offloading to a background isolate via [compute]
  /// when the line count meets or exceeds [isolateThreshold] (default 50 lines).
  Future<List<DeviceLogEntry>> parseBatchAsync(
    List<String> lines,
    int startingId, {
    int isolateThreshold = 50,
  }) async {
    if (lines.isEmpty) return const [];
    if (lines.length < isolateThreshold) {
      return parseLines(lines, startingId);
    }
    return compute(
      parseLogcatBatchInIsolate,
      LogcatBatchPayload(lines: lines, startingId: startingId),
    );
  }

  /// Parses a single line of logcat output.
  DeviceLogEntry parseLine(String line, int monotonicId) {
    final trimmed = line.trimRight();
    final match = _threadtimeRegex.firstMatch(trimmed);

    if (match != null) {
      final timeStr = match.group(1)!;
      final pid = int.tryParse(match.group(2)!) ?? 0;
      final tid = int.tryParse(match.group(3)!) ?? 0;
      final levelCode = match.group(4)!;
      final tag = match.group(5)!.trim();
      final message = match.group(6) ?? '';

      return DeviceLogEntry(
        id: monotonicId,
        timestamp: _parseTimestamp(timeStr),
        pid: pid,
        tid: tid,
        level: LogLevel.fromCode(levelCode),
        tag: tag,
        message: message,
        rawLine: trimmed,
      );
    }

    // Handle system notices (e.g. "--------- beginning of main") or unformatted stack traces
    final isSystemMarker = trimmed.startsWith('--------- beginning of');
    return DeviceLogEntry(
      id: monotonicId,
      timestamp: DateTime.now(),
      pid: 0,
      tid: 0,
      level: isSystemMarker ? LogLevel.info : LogLevel.unknown,
      tag: isSystemMarker ? 'System' : '',
      message: trimmed,
      rawLine: trimmed,
    );
  }

  DateTime _parseTimestamp(String timeStr) {
    try {
      // timeStr example: "10-14 10:48:15.836"
      final parts = timeStr.split(' ');
      final dateParts = parts[0].split('-');
      final timeParts = parts[1].split(':');
      final secParts = timeParts[2].split('.');

      final now = DateTime.now();
      final month = int.parse(dateParts[0]);
      final day = int.parse(dateParts[1]);
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final second = int.parse(secParts[0]);
      final millisecond = int.parse(secParts[1]);

      return DateTime(now.year, month, day, hour, minute, second, millisecond);
    } catch (_) {
      return DateTime.now();
    }
  }
}
