import 'dart:io';

import 'package:desk_droid/core/constants/mcp_status_constants.dart';
import 'package:desk_droid/core/models/mcp_activity_event.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_activity_recorder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory temp;
  late File file;
  late List<String> errors;
  final at = DateTime.utc(2026, 10, 18, 12);

  setUp(() {
    temp = Directory.systemTemp.createTempSync('mcp_activity_');
    file = File('${temp.path}/nested/4242.jsonl');
    errors = [];
  });

  tearDown(() => temp.deleteSync(recursive: true));

  FileMcpActivityRecorder recorder({String? path}) => FileMcpActivityRecorder(
    filePath: path ?? file.path,
    clock: () => at,
    onError: errors.add,
  );

  List<McpActivityEvent> events() =>
      file.readAsLinesSync().map(McpActivityEvent.tryParse).nonNulls.toList();

  void call(McpActivitySink sink, String tool) => sink.toolCalled(
    tool: tool,
    deviceSerial: 'R9',
    succeeded: true,
    duration: const Duration(milliseconds: 30),
  );

  test('writes the session, then one line per tool call', () {
    final sink = recorder()..sessionStarted('claude-ai');
    call(sink, 'android_tap');
    call(sink, 'android_swipe');

    expect(events().map((e) => e.tool ?? e.clientName), [
      'claude-ai',
      'android_tap',
      'android_swipe',
    ]);
  });

  test('stays small: rewrites with the session and the newest calls', () {
    final sink = recorder()..sessionStarted('cursor');
    for (var i = 0; i < McpStatusConstants.activityMaxLines + 5; i++) {
      call(sink, 'tool_$i');
    }
    final lines = events();
    expect(
      lines.length,
      lessThanOrEqualTo(McpStatusConstants.activityMaxLines),
    );
    expect(lines.first.clientName, 'cursor');
    expect(lines.last.tool, 'tool_${McpStatusConstants.activityMaxLines + 4}');
  });

  test('re-creates a deleted file with the session line', () {
    final sink = recorder()..sessionStarted('claude-ai');
    file.deleteSync();
    call(sink, 'android_tap');
    expect(events().first.clientName, 'claude-ai');
    expect(events().last.tool, 'android_tap');
  });

  test('close deletes the file', () async {
    final sink = recorder()..sessionStarted('claude-ai');
    await sink.close();
    expect(file.existsSync(), isFalse);
  });

  test('a write failure is reported, never thrown', () {
    final blocker = File('${temp.path}/blocker')..writeAsStringSync('x');
    recorder(path: '${blocker.path}/1.jsonl').sessionStarted('claude-ai');
    expect(errors.single, contains('Could not write activity file'));
  });
}
