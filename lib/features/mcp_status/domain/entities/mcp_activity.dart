import 'package:desk_droid/core/models/mcp_activity_event.dart';
import 'package:equatable/equatable.dart';

/// A tool call, with the AI client session that made it.
class McpActivityEntry extends Equatable {
  const McpActivityEntry({
    required this.pid,
    required this.event,
    this.clientName,
  });

  final int pid;
  final String? clientName;
  final McpActivityEvent event;

  @override
  List<Object?> get props => [pid, clientName, event];
}

/// One AI client session (one server process) and its latest tool call.
class McpSessionActivity extends Equatable {
  const McpSessionActivity({
    required this.pid,
    required this.startedAt,
    this.clientName,
    this.lastCall,
  });

  final int pid;
  final String? clientName;
  final DateTime startedAt;
  final McpActivityEvent? lastCall;

  @override
  List<Object?> get props => [pid, clientName, startedAt, lastCall];
}

/// What AI clients are doing now, from the servers' activity files.
class McpActivitySnapshot extends Equatable {
  const McpActivitySnapshot({
    this.sessions = const [],
    this.recent = const [],
    this.activeByDevice = const {},
  });

  /// Sessions whose server process still runs, newest first.
  final List<McpSessionActivity> sessions;

  /// The newest tool calls across all sessions, newest first.
  final List<McpActivityEntry> recent;

  /// The latest call per device made within the active window: the devices
  /// an AI is controlling now.
  final Map<String, McpActivityEntry> activeByDevice;

  @override
  List<Object?> get props => [sessions, recent, activeByDevice];
}
