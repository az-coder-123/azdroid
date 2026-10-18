import 'dart:io';

import 'package:desk_droid/core/constants/mcp_status_constants.dart';
import 'package:desk_droid/core/extensions/line_split_extension.dart';
import 'package:desk_droid/core/models/mcp_activity_event.dart';
import 'package:desk_droid/core/services/app_logger.dart';
import 'package:desk_droid/core/services/mcp_activity_paths.dart';
import 'package:desk_droid/features/mcp_status/data/datasources/mcp_file_probe.dart';

/// Reads the activity files that MCP servers write (one per process), and
/// removes the files of servers that ended without cleaning up.
class McpActivityReader {
  McpActivityReader({
    required McpActivityPaths paths,
    McpFileProbe files = const IoMcpFileProbe(),
  }) : _activityPaths = paths,
       _fileProbe = files;

  final McpActivityPaths _activityPaths;
  final McpFileProbe _fileProbe;

  /// Events per server process id, in file order. Unreadable files and
  /// half-written lines are skipped.
  Future<Map<int, List<McpActivityEvent>>> readAll() async {
    final result = <int, List<McpActivityEvent>>{};
    for (final (pid, path) in _activityFiles()) {
      try {
        final text = await _fileProbe.readText(path);
        result[pid] = [
          ...text.splitLines().map(McpActivityEvent.tryParse).nonNulls,
        ];
      } on FileSystemException catch (error) {
        // The server may delete its file between listing and reading.
        AppLogger.debug('Skipping MCP activity file $path: $error');
      }
    }
    return result;
  }

  /// Deletes files whose process is not in [livePids] and that have not
  /// changed for [McpStatusConstants.staleActivityAge] (a killed server, or
  /// a crash). The age check keeps sessions the process list misses (a
  /// `dart run` server on Windows).
  Future<void> pruneStale({
    required Set<int> livePids,
    required DateTime now,
  }) async {
    final cutoff = now.subtract(McpStatusConstants.staleActivityAge);
    for (final (pid, path) in _activityFiles()) {
      if (livePids.contains(pid)) continue;
      try {
        if (_fileProbe.modifiedAt(path).isBefore(cutoff)) {
          await _fileProbe.delete(path);
        }
      } on FileSystemException catch (error) {
        AppLogger.debug('Could not prune MCP activity file $path: $error');
      }
    }
  }

  Iterable<(int, String)> _activityFiles() sync* {
    for (final path in _fileProbe.listFiles(_activityPaths.directory)) {
      final pid = _activityPaths.pidOf(path);
      if (pid != null) yield (pid, path);
    }
  }
}
