import 'package:desk_droid/core/constants/mcp_status_constants.dart';
import 'package:desk_droid/core/models/mcp_activity_event.dart';
import 'package:desk_droid/features/mcp_status/domain/services/mcp_activity_snapshot_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 10, 18, 12);
  McpActivityEvent start(int secondsAgo, String client) =>
      McpActivityEvent.sessionStart(
        at: now.subtract(Duration(seconds: secondsAgo)),
        clientName: client,
      );
  McpActivityEvent tool(int secondsAgo, String name, [String? device = 'R9']) =>
      McpActivityEvent.toolCall(
        at: now.subtract(Duration(seconds: secondsAgo)),
        tool: name,
        deviceSerial: device,
        succeeded: true,
        durationMs: 10,
      );

  test('live sessions, newest first, with their last call', () {
    final snapshot = buildMcpActivitySnapshot(
      eventsByPid: {
        1: [start(300, 'claude-ai'), tool(200, 'a'), tool(100, 'b')],
        2: [start(60, 'cursor')],
        3: [start(30, 'gone')],
      },
      livePids: {1, 2},
      now: now,
    );
    expect(snapshot.sessions.map((s) => s.clientName), ['cursor', 'claude-ai']);
    expect(snapshot.sessions.last.lastCall?.tool, 'b');
    expect(snapshot.sessions.first.lastCall, isNull);
  });

  test('unknown live processes keep every file as a session', () {
    final snapshot = buildMcpActivitySnapshot(
      eventsByPid: {
        3: [start(30, 'gone')],
      },
      livePids: null,
      now: now,
    );
    expect(snapshot.sessions, hasLength(1));
  });

  test('recent calls are merged across sessions, newest first, limited', () {
    final many = [
      for (var i = 0; i < McpStatusConstants.recentActivityLimit + 3; i++)
        tool(100 + i, 'old_$i'),
    ];
    final snapshot = buildMcpActivitySnapshot(
      eventsByPid: {
        1: [start(900, 'claude-ai'), ...many],
        2: [start(50, 'cursor'), tool(1, 'newest')],
      },
      livePids: {1, 2},
      now: now,
    );
    expect(snapshot.recent, hasLength(McpStatusConstants.recentActivityLimit));
    expect(snapshot.recent.first.event.tool, 'newest');
    expect(snapshot.recent.first.clientName, 'cursor');
  });

  test('a device is active only within the window, latest caller wins', () {
    final window = McpStatusConstants.activeWindow.inSeconds;
    final snapshot = buildMcpActivitySnapshot(
      eventsByPid: {
        1: [start(900, 'claude-ai'), tool(2, 'android_tap')],
        2: [start(900, 'cursor'), tool(1, 'android_swipe')],
        3: [start(900, 'x'), tool(window + 1, 'stale', 'OLD')],
        4: [start(900, 'y'), tool(1, 'android_list_devices', null)],
      },
      livePids: null,
      now: now,
    );
    expect(snapshot.activeByDevice.keys, ['R9']);
    expect(snapshot.activeByDevice['R9']?.clientName, 'cursor');
  });
}
