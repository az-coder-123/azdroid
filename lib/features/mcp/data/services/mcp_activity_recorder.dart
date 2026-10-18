import 'dart:io';

import 'package:desk_droid/core/constants/mcp_status_constants.dart';
import 'package:desk_droid/core/models/mcp_activity_event.dart';

/// Receives what the MCP server does, for the DeskDroid app to display.
abstract class McpActivitySink {
  /// The AI client connected (`initialize`).
  void sessionStarted(String? clientName);

  /// A tool call finished.
  void toolCalled({
    required String tool,
    required String? deviceSerial,
    required bool succeeded,
    required Duration duration,
  });

  /// The client disconnected; removes this session's record.
  Future<void> close();
}

/// [McpActivitySink] that records nothing (tests, or when disabled).
class NoopMcpActivitySink implements McpActivitySink {
  const NoopMcpActivitySink();

  @override
  void sessionStarted(String? clientName) {}

  @override
  void toolCalled({
    required String tool,
    required String? deviceSerial,
    required bool succeeded,
    required Duration duration,
  }) {}

  @override
  Future<void> close() async {}
}

/// Appends events to this process's activity file (JSON lines).
///
/// Recording must never break the server: write failures go to stderr
/// (stdout carries the protocol). The file is created on the first event,
/// re-created with the session line if something deleted it, kept small by
/// rewriting, and deleted on [close].
class FileMcpActivityRecorder implements McpActivitySink {
  FileMcpActivityRecorder({
    required String filePath,
    DateTime Function()? clock,
    void Function(String message)? onError,
  }) : _file = File(filePath),
       _now = clock ?? DateTime.now,
       _report = onError ?? stderr.writeln;

  final File _file;
  final DateTime Function() _now;
  final void Function(String message) _report;

  McpActivityEvent? _start;
  final List<String> _recent = [];
  int _linesInFile = 0;

  @override
  void sessionStarted(String? clientName) {
    _start = McpActivityEvent.sessionStart(at: _now(), clientName: clientName);
    _rewrite();
  }

  @override
  void toolCalled({
    required String tool,
    required String? deviceSerial,
    required bool succeeded,
    required Duration duration,
  }) {
    final line = McpActivityEvent.toolCall(
      at: _now(),
      tool: tool,
      deviceSerial: deviceSerial,
      succeeded: succeeded,
      durationMs: duration.inMilliseconds,
    ).toLine();
    _recent.add(line);
    if (_recent.length > McpStatusConstants.activityKeptLines) {
      _recent.removeAt(0);
    }
    if (!_file.existsSync() ||
        _linesInFile >= McpStatusConstants.activityMaxLines) {
      _rewrite();
    } else {
      _append('$line\n');
      _linesInFile++;
    }
  }

  @override
  Future<void> close() async {
    try {
      if (_file.existsSync()) await _file.delete();
    } on FileSystemException catch (error) {
      _report('[DeskDroid MCP] Could not remove activity file: $error');
    }
  }

  /// Writes the session line and the newest calls, replacing the file.
  void _rewrite() {
    final start =
        _start ?? McpActivityEvent.sessionStart(at: _now(), clientName: null);
    final lines = [start.toLine(), ..._recent];
    try {
      _file.parent.createSync(recursive: true);
      _file.writeAsStringSync('${lines.join('\n')}\n', flush: true);
      _linesInFile = lines.length;
    } on FileSystemException catch (error) {
      _report('[DeskDroid MCP] Could not write activity file: $error');
    }
  }

  void _append(String text) {
    try {
      _file.writeAsStringSync(text, mode: FileMode.append, flush: true);
    } on FileSystemException catch (error) {
      _report('[DeskDroid MCP] Could not append activity: $error');
    }
  }
}
