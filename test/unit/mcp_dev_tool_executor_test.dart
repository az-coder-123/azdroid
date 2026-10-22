import 'dart:io';

import 'package:desk_droid/features/mcp/data/handlers/mcp_tool_executor.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_adb_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAdb extends Mock implements McpAdbClient {}

ProcessResult _ok([String out = '']) => ProcessResult(1, 0, out, '');

void main() {
  const serial = 'M13';
  late _MockAdb adb;
  late McpToolExecutor executor;
  late List<String> commands;

  void script(Map<String, String> byContains) {
    when(() => adb.run(any())).thenAnswer((invocation) async {
      final line = (invocation.positionalArguments.first as List<String>).join(
        ' ',
      );
      commands.add(line);
      for (final MapEntry(:key, :value) in byContains.entries) {
        if (line.contains(key)) return _ok(value);
      }
      return _ok();
    });
  }

  setUp(() {
    adb = _MockAdb();
    commands = [];
    executor = McpToolExecutor(adbClient: adb);
  });

  Future<String> call(String tool, Map<String, dynamic> args) async {
    final r = await executor.execute(tool, {'deviceSerial': serial, ...args});
    return '${r.isError ? 'ERR ' : ''}${r.content.first.text}';
  }

  group('app logs', () {
    test('reads only the running app since N seconds ago', () async {
      script({'pidof': '4242\n', 'date': '1792667228\n'});
      when(
        () => adb.getLogcat(
          serial,
          tag: any(named: 'tag'),
          level: any(named: 'level'),
          limit: any(named: 'limit'),
          pid: 4242,
          sinceEpochSeconds: 1792667198,
        ),
      ).thenAnswer((_) async => 'I MyApp: started');
      final out = await call('android_get_logcat', {
        'package': 'com.example',
        'sinceSeconds': 30,
      });
      expect(out, contains('com.example (pid 4242), last 30s'));
      expect(out, contains('I MyApp: started'));
    });

    test('an app that is not running gets a clear error', () async {
      script({'pidof': ''});
      final out = await call('android_get_logcat', {'package': 'com.example'});
      expect(out, startsWith('ERR com.example is not running'));
      expect(out, contains('crashesOnly'));
    });
  });

  test('fps picks the window that drew the most frames', () async {
    script({
      '--list':
          'ActivityRecord{1 u0 com.example/.Main}#1\n'
          'com.example/com.example.Main#2\n'
          'SurfaceView[com.example/com.example.Main](BLAST)#3\n',
      '--latency ':
          "@@layer 16666666\n0\t0\t0\n"
          "@@layer 16666666\n1\t1000000\t1\n1\t17666666\t1\n1\t34333332\t1\n",
    });
    final out = await call('android_get_device_stats', {
      'kind': 'fps',
      'package': 'com.example',
      'durationMs': 0,
    });
    expect(out, contains('SurfaceView[com.example/com.example.Main](BLAST)#3'));
    expect(out, contains('fps while drawing: 60.0 (display 60 Hz)'));
    // The activity record holds no buffers and is not queried.
    expect(commands.last, isNot(contains('ActivityRecord')));
    expect(commands.any((c) => c.contains('--latency-clear')), isFalse);
  });

  test('display config validates before changing anything', () async {
    script({});
    final out = await call('android_set_display_config', {'size': 'big'});
    expect(out, startsWith('ERR size is WIDTHxHEIGHT'));
    expect(commands, isEmpty);
  });

  test(
    'instrumentation without a test APK explains how to install it',
    () async {
      script({'list instrumentation': ''});
      final out = await call('android_run_instrumentation', {
        'package': 'com.example',
      });
      expect(out, startsWith('ERR No test APK for com.example'));
      expect(out, contains('installDebugAndroidTest'));
    },
  );
}
