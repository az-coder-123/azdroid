import 'dart:convert';

import 'package:desk_droid/core/models/mcp_activity_event.dart';
import 'package:desk_droid/features/mcp_status/data/datasources/mcp_activity_reader.dart';
import 'package:desk_droid/features/mcp_status/data/datasources/mcp_binary_inspector.dart';
import 'package:desk_droid/features/mcp_status/data/datasources/mcp_client_config_reader.dart';
import 'package:desk_droid/features/mcp_status/data/datasources/mcp_process_lister.dart';
import 'package:desk_droid/features/mcp_status/data/repositories/mcp_status_repository_impl.dart';
import 'package:desk_droid/features/mcp_status/data/services/mcp_config_snippet.dart';
import 'package:desk_droid/features/mcp_status/domain/entities/mcp_binary_status.dart';
import 'package:desk_droid/features/mcp_status/domain/entities/mcp_client_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockInspector extends Mock implements McpBinaryInspector {}

class _MockReader extends Mock implements McpClientConfigReader {}

class _MockLister extends Mock implements McpProcessLister {}

class _MockActivity extends Mock implements McpActivityReader {}

void main() {
  test('the snippet is valid JSON and escapes Windows backslashes', () {
    const exe = r'C:\Apps\DeskDroid\deskdroid-mcp.exe';
    final json = jsonDecode(buildMcpConfigSnippet(exe)) as Map<String, Object?>;
    final servers = json['mcpServers']! as Map<String, Object?>;
    final entry = servers['deskdroid']! as Map<String, Object?>;
    expect(entry['command'], exe);
  });

  test('load lists sessions before the handshake starts a server', () async {
    final inspector = _MockInspector();
    final reader = _MockReader();
    final lister = _MockLister();
    final activity = _MockActivity();
    final now = DateTime.utc(2026, 10, 18, 12);
    final order = <String>[];
    const client = (name: 'Cursor', configPath: '/c.json');
    when(lister.listPids).thenAnswer((_) async {
      order.add('list');
      return {42};
    });
    when(() => activity.pruneStale(livePids: {42}, now: now))
        .thenAnswer((_) async {});
    when(activity.readAll).thenAnswer(
      (_) async => {
        42: [
          McpActivityEvent.sessionStart(at: now, clientName: 'claude-ai'),
          McpActivityEvent.toolCall(
            at: now,
            tool: 'android_tap',
            deviceSerial: 'R9',
            succeeded: true,
            durationMs: 80,
          ),
        ],
      },
    );
    when(inspector.inspect).thenAnswer((_) async {
      order.add('inspect');
      return const McpBinaryStatus(
        availability: McpBinaryAvailability.ready,
        executablePath: '/x',
      );
    });
    when(() => reader.read(client)).thenAnswer(
      (_) async => const McpClientStatus(
        name: 'Cursor',
        configPath: '/c.json',
        setup: McpClientSetup.configured,
      ),
    );

    final status = await McpStatusRepositoryImpl(
      binaryInspector: inspector,
      configReader: reader,
      processLister: lister,
      activityReader: activity,
      clients: const [client],
      clock: () => now,
    ).load();

    expect(order, ['list', 'inspect']);
    expect(status.runningSessions, 1);
    expect(status.anyClientConfigured, isTrue);
    expect(status.activity.sessions.single.clientName, 'claude-ai');
    expect(status.activity.activeByDevice.keys, ['R9']);
    verify(() => activity.pruneStale(livePids: {42}, now: now)).called(1);
  });
}
