import 'dart:io';

import 'package:desk_droid/features/mcp/data/handlers/mcp_tool_executor.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_adb_client.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_shell_result.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_text_entry.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_unsupported_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAdb extends Mock implements McpAdbClient {}

/// Output of `adb shell cmd <service>` when the service has no shell
/// command: exit code 0 (seen on Android 10 and 13).
ProcessResult _missing() =>
    ProcessResult(1, 0, 'No shell command implementation.', '');

ProcessResult _ok([String out = '']) => ProcessResult(1, 0, out, '');

void main() {
  const serial = 'R9';
  late _MockAdb adb;
  late List<List<String>> commands;

  /// Answers each command with the first matching scripted result.
  void script(Map<String, ProcessResult> byContains) {
    when(() => adb.run(any())).thenAnswer((invocation) async {
      final args = invocation.positionalArguments.first as List<String>;
      commands.add(args);
      final line = args.join(' ');
      for (final MapEntry(:key, :value) in byContains.entries) {
        if (line.contains(key)) return value;
      }
      return _ok();
    });
  }

  setUp(() {
    adb = _MockAdb();
    commands = [];
  });

  test('a missing shell command is not a success, even with exit code 0', () {
    expect(_missing().succeeded, isFalse);
    expect(_missing().isMissingCommand, isTrue);
    expect(_ok('true').succeeded, isTrue);
  });

  group('text', () {
    test(
      'type_text quotes the text, so the device shell cannot run it',
      () async {
        script({});
        await McpAdbTextOps.typeText(adb, serial, "it's a; reboot");
        // One argument, single-quoted: `;` and `'` stay text.
        expect(commands.single.last, "'it'\\''s%sa;%sreboot'");
      },
    );

    test('type_text rejects non-ASCII instead of crashing input', () {
      script({});
      expect(
        () => McpAdbTextOps.typeText(adb, serial, 'Xin chào'),
        throwsA(isA<McpUnsupportedOnDeviceException>()),
      );
      expect(commands, isEmpty);
    });

    test('set_text types ASCII when the clipboard is missing', () async {
      script({'clipboard': _missing()});
      final entry = await McpAdbTextOps.setText(adb, serial, 'hello');
      expect(entry, McpTextEntry.typed);
      expect(commands.last, contains("'hello'"));
      // It never pastes a stale clipboard.
      expect(commands.any((c) => c.contains('279')), isFalse);
    });

    test('set_text refuses non-ASCII text without a clipboard', () {
      script({'clipboard': _missing()});
      expect(
        () => McpAdbTextOps.setText(adb, serial, 'Xin chào'),
        throwsA(isA<McpUnsupportedOnDeviceException>()),
      );
    });

    test('set_text pastes when the clipboard works', () async {
      script({});
      final entry = await McpAdbTextOps.setText(adb, serial, 'Xin chào');
      expect(entry, McpTextEntry.pasted);
      expect(commands.first.last, "'Xin chào'");
      expect(commands.last.last, '279');
    });
  });

  group('clipboard', () {
    test(
      'reading without cmd clipboard is an error, not its message',
      () async {
        script({'clipboard': _missing()});
        expect(
          () => McpAdbDeviceOps.getClipboard(adb, serial),
          throwsA(isA<McpUnsupportedOnDeviceException>()),
        );
      },
    );
  });

  group('biometric', () {
    test('physical devices are refused; emulators use adb emu', () async {
      script({});
      expect(
        () => McpAdbMediaProcOps.simulateBiometric(adb, serial),
        throwsA(isA<McpUnsupportedOnDeviceException>()),
      );
      await McpAdbMediaProcOps.simulateBiometric(adb, 'emulator-5554');
      expect(commands.single, [
        '-s', 'emulator-5554', 'emu', 'finger', 'touch', '1', //
      ]);
    });
  });

  group('mock location', () {
    test('Android without cmd location is refused before any change', () {
      script({'cmd location': _missing()});
      expect(
        () => McpAdbEnvironmentOps.setLocation(
          adb,
          serial,
          latitude: 10.7,
          longitude: 106.7,
        ),
        throwsA(isA<McpUnsupportedOnDeviceException>()),
      );
    });

    test('location turned off is reported, never switched on', () async {
      script({'is-location-enabled': _ok('false')});
      await expectLater(
        McpAdbEnvironmentOps.setLocation(
          adb,
          serial,
          latitude: 1,
          longitude: 2,
        ),
        throwsA(isA<McpUnsupportedOnDeviceException>()),
      );
      expect(commands.map((c) => c.join(' ')), [
        '-s R9 shell cmd location is-location-enabled',
      ]);
    });

    test(
      'sets gps and network test providers, and reset removes them',
      () async {
        script({'is-location-enabled': _ok('true')});
        await McpAdbEnvironmentOps.setLocation(
          adb,
          serial,
          latitude: 10.7,
          longitude: 106.7,
        );
        final lines = commands.map((c) => c.skip(3).join(' ')).toList();
        expect(
          lines,
          contains('appops set com.android.shell android:mock_location allow'),
        );
        expect(
          lines,
          contains(
            'cmd location providers set-test-provider-location gps --location 10.7,106.7',
          ),
        );
        expect(
          lines,
          contains(
            'cmd location providers set-test-provider-location network --location 10.7,106.7',
          ),
        );

        commands.clear();
        await McpAdbEnvironmentOps.resetLocation(adb, serial);
        expect(commands.map((c) => c.skip(3).join(' ')), [
          'cmd location providers remove-test-provider gps',
          'cmd location providers remove-test-provider network',
          'appops set com.android.shell android:mock_location default',
        ]);
      },
    );
  });

  group('notifications', () {
    test('snooze quotes the key, whose | would be a shell pipe', () async {
      script({});
      await McpAdbNotificationButtonOps.snoozeNotification(
        adb,
        serial,
        key: '0|com.app|2|tag|10202',
        hideFor: const Duration(minutes: 1),
      );
      expect(commands.single.sublist(3), [
        'cmd', 'notification', 'snooze', '--for', '60000',
        "'0|com.app|2|tag|10202'", //
      ]);
    });

    test('notifications carry their key', () async {
      script({
        'dumpsys notification': _ok(
          '  NotificationRecord(0x1: pkg=com.app user=UserHandle{0} id=2\n'
          '      key=0|com.app|2|tag|10202\n'
          '        android.title=String (Code)\n'
          '        android.text=SpannableString (123456\n'
          '        second line)\n',
        ),
      });
      final list = await McpAdbNotificationButtonOps.getNotifications(
        adb,
        serial,
      );
      expect(list.single['key'], '0|com.app|2|tag|10202');
      // Android 13 wraps extras as `String (…)`.
      expect(list.single['title'], 'Code');
      expect(list.single['text'], '123456');
    });
  });

  group('device selection', () {
    test('several devices and no serial: refuse with the list', () async {
      when(adb.getConnectedSerials).thenAnswer((_) async => ['A1', 'B2']);
      final res = await McpToolExecutor(adbClient: adb)
          .execute('android_get_current_app', {});
      expect(res.isError, isTrue);
      expect(res.content.first.text, contains('A1, B2'));
      expect(res.content.first.text, contains('deviceSerial'));
    });
  });

  test('logcat filters first, then keeps the newest lines', () async {
    script({'logcat': _ok('E a\nE b\nE c\nE d')});
    final tail = await McpAdbCmdOps.getLogcat(
      adb,
      serial,
      level: 'w',
      limit: 2,
    );
    await McpAdbCmdOps.getLogcat(adb, serial, tag: 'MyApp', level: 'E');
    await McpAdbCmdOps.getLogcat(adb, serial, limit: 7);

    // `-t` would cut the buffer before the filter: never with a filter.
    expect(commands[0], ['-s', serial, 'logcat', '-d', '*:W']);
    expect(tail, 'E c\nE d');
    expect(commands[1].sublist(4), ['-s', 'MyApp:E']);
    expect(commands[2], ['-s', serial, 'logcat', '-d', '-t', '7']);
  });
}
