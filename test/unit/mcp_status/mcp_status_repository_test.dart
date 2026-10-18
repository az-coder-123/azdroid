import 'dart:convert';

import 'package:desk_droid/features/mcp_status/data/datasources/mcp_binary_inspector.dart';
import 'package:desk_droid/features/mcp_status/data/datasources/mcp_client_config_reader.dart';
import 'package:desk_droid/features/mcp_status/data/datasources/mcp_process_counter.dart';
import 'package:desk_droid/features/mcp_status/data/repositories/mcp_status_repository_impl.dart';
import 'package:desk_droid/features/mcp_status/data/services/mcp_config_snippet.dart';
import 'package:desk_droid/features/mcp_status/domain/entities/mcp_binary_status.dart';
import 'package:desk_droid/features/mcp_status/domain/entities/mcp_client_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockInspector extends Mock implements McpBinaryInspector {}

class _MockReader extends Mock implements McpClientConfigReader {}

class _MockCounter extends Mock implements McpProcessCounter {}

void main() {
  test('the snippet is valid JSON and escapes Windows backslashes', () {
    const exe = r'C:\Apps\DeskDroid\deskdroid-mcp.exe';
    final json = jsonDecode(buildMcpConfigSnippet(exe)) as Map<String, Object?>;
    final servers = json['mcpServers']! as Map<String, Object?>;
    final entry = servers['deskdroid']! as Map<String, Object?>;
    expect(entry['command'], exe);
  });

  test('load counts sessions before the handshake starts a server', () async {
    final inspector = _MockInspector();
    final reader = _MockReader();
    final counter = _MockCounter();
    final order = <String>[];
    const client = (name: 'Cursor', configPath: '/c.json');
    when(counter.count).thenAnswer((_) async {
      order.add('count');
      return 1;
    });
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
      processCounter: counter,
      clients: const [client],
    ).load();

    expect(order, ['count', 'inspect']);
    expect(status.runningSessions, 1);
    expect(status.anyClientConfigured, isTrue);
  });
}
