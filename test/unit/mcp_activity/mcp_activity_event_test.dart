import 'package:desk_droid/core/models/mcp_activity_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final at = DateTime.utc(2026, 10, 18, 9, 30, 5);

  test('a tool call survives a round trip as one line', () {
    final call = McpActivityEvent.toolCall(
      at: at,
      tool: 'android_tap',
      deviceSerial: '192.168.1.3:5555',
      succeeded: false,
      durationMs: 120,
    );
    final line = call.toLine();
    expect(line, isNot(contains('\n')));
    expect(McpActivityEvent.tryParse(line), call);
  });

  test('a session start keeps the client name and omits empty fields', () {
    final start = McpActivityEvent.sessionStart(at: at, clientName: 'cursor');
    expect(start.toLine(), isNot(contains('tool')));
    expect(McpActivityEvent.tryParse(start.toLine()), start);
  });

  test('blank, half-written, or unknown lines are skipped', () {
    expect(McpActivityEvent.tryParse(''), isNull);
    expect(McpActivityEvent.tryParse('{"kind":"tool","at":"2026-'), isNull);
    expect(McpActivityEvent.tryParse('{"kind":"other","at":"$at"}'), isNull);
    expect(McpActivityEvent.tryParse('[1,2]'), isNull);
  });
}
