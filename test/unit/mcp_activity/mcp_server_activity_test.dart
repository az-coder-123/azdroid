import 'package:desk_droid/features/mcp/data/handlers/mcp_protocol_handler.dart';
import 'package:desk_droid/features/mcp/data/handlers/mcp_tool_executor.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_activity_recorder.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_adb_client.dart';
import 'package:desk_droid/features/mcp/data/transports/mcp_stdio_transport.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAdb extends Mock implements McpAdbClient {}

/// Records what the server reports, for assertions.
class _SpySink implements McpActivitySink {
  final List<String> log = [];

  @override
  void sessionStarted(String? clientName) => log.add('start $clientName');

  @override
  void toolCalled({
    required String tool,
    required String? deviceSerial,
    required bool succeeded,
    required Duration duration,
  }) => log.add('$tool $deviceSerial ${succeeded ? 'ok' : 'failed'}');

  @override
  Future<void> close() async => log.add('close');
}

void main() {
  late _MockAdb adb;
  late _SpySink sink;

  setUp(() {
    adb = _MockAdb();
    sink = _SpySink();
  });

  test('each tool call is reported with the device it resolved to', () async {
    final executor = McpToolExecutor(adbClient: adb, activity: sink);
    when(adb.getConnectedSerials).thenAnswer((_) async => ['R9']);
    when(() => adb.tap('R9', 0.5, 0.5)).thenAnswer((_) async => true);
    when(adb.listDevicesRaw).thenAnswer((_) async => 'R9 device');

    await executor.execute('android_tap', {'x': 0.5, 'y': 0.5});
    await executor.execute('android_list_devices', {});
    await executor.execute('no_such_tool', {'deviceSerial': 'X1'});

    expect(sink.log, [
      'android_tap R9 ok',
      'android_list_devices null ok',
      'no_such_tool X1 failed',
    ]);
  });

  test('a call without any device is reported as failed', () async {
    when(adb.getConnectedSerials).thenAnswer((_) async => []);
    await McpToolExecutor(
      adbClient: adb,
      activity: sink,
    ).execute('android_tap', {'x': 0.1, 'y': 0.1});
    expect(sink.log, ['android_tap null failed']);
  });

  test(
    'initialize names the client; end of input closes the session',
    () async {
      final transport = McpStdioTransport(
        handler: McpProtocolHandler(activity: sink),
        inputStream: Stream.fromIterable([
          '{"jsonrpc":"2.0","id":1,"method":"initialize","params":'
              '{"clientInfo":{"name":"claude-ai","version":"1.0"}}}',
          '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}',
        ]),
        outputSink: (_) {},
      );
      await transport.run();
      expect(sink.log, ['start claude-ai', 'close']);
    },
  );
}
