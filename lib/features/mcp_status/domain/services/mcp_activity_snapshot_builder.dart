import 'package:desk_droid/core/constants/mcp_status_constants.dart';
import 'package:desk_droid/core/models/mcp_activity_event.dart';
import 'package:desk_droid/features/mcp_status/domain/entities/mcp_activity.dart';

/// Builds an [McpActivitySnapshot] from the parsed activity files.
///
/// [eventsByPid] maps each server process id to its events in file order.
/// [livePids] are the server processes that run now; `null` when unknown,
/// in which case every file counts as a live session.
McpActivitySnapshot buildMcpActivitySnapshot({
  required Map<int, List<McpActivityEvent>> eventsByPid,
  required Set<int>? livePids,
  required DateTime now,
}) {
  final sessions = <McpSessionActivity>[];
  final calls = <McpActivityEntry>[];
  for (final MapEntry(key: pid, value: events) in eventsByPid.entries) {
    final start = events
        .where((e) => e.kind == McpActivityKind.sessionStart)
        .lastOrNull;
    final toolCalls = events.where((e) => e.kind == McpActivityKind.toolCall);
    for (final call in toolCalls) {
      calls.add(
        McpActivityEntry(pid: pid, clientName: start?.clientName, event: call),
      );
    }
    final firstAt = start?.at ?? events.firstOrNull?.at;
    if (firstAt == null) continue;
    if (livePids == null || livePids.contains(pid)) {
      sessions.add(
        McpSessionActivity(
          pid: pid,
          clientName: start?.clientName,
          startedAt: firstAt,
          lastCall: toolCalls.lastOrNull,
        ),
      );
    }
  }
  calls.sort((a, b) => b.event.at.compareTo(a.event.at));
  sessions.sort((a, b) => b.startedAt.compareTo(a.startedAt));

  final activeSince = now.subtract(McpStatusConstants.activeWindow);
  final active = <String, McpActivityEntry>{};
  for (final entry in calls) {
    final serial = entry.event.deviceSerial;
    if (serial == null || entry.event.at.isBefore(activeSince)) continue;
    active.putIfAbsent(serial, () => entry); // Newest first.
  }
  return McpActivitySnapshot(
    sessions: sessions,
    recent: calls.take(McpStatusConstants.recentActivityLimit).toList(),
    activeByDevice: active,
  );
}
