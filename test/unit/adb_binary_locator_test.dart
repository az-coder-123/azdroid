import 'dart:io';

import 'package:desk_droid/core/platform/host_os.dart';
import 'package:desk_droid/core/platform/host_toolchain.dart';
import 'package:desk_droid/core/services/adb_binary_locator.dart';
import 'package:desk_droid/core/services/process_executor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/test_toolchains.dart';

class MockProcessExecutor extends Mock implements ProcessExecutor {}

void main() {
  late MockProcessExecutor executor;
  late List<String> probeFailures;

  setUp(() {
    executor = MockProcessExecutor();
    probeFailures = [];
  });

  AdbBinaryLocator buildLocator(
    HostToolchain toolchain, {
    Set<String> existingFiles = const {},
  }) {
    return AdbBinaryLocator(
      toolchain: toolchain,
      executor: executor,
      fileExists: (path) async => existingFiles.contains(path),
      onProbeFailure: (probe, _) => probeFailures.add(probe),
    );
  }

  group('AdbBinaryLocator on macOS', () {
    final mac = toolchainFor(HostOs.macos, {'HOME': '/Users/dev'});

    void stubWhich(ProcessResult result) {
      when(() => executor.run('/usr/bin/which', ['adb']))
          .thenAnswer((_) async => result);
    }

    test('returns path reported by which when the file exists', () async {
      stubWhich(ProcessResult(0, 0, '/opt/homebrew/bin/adb\n', ''));
      final locator = buildLocator(
        mac,
        existingFiles: {'/opt/homebrew/bin/adb'},
      );

      expect(await locator.locate(), '/opt/homebrew/bin/adb');
    });

    test('falls back to the default SDK folder when which fails', () async {
      stubWhich(ProcessResult(0, 1, '', 'not found'));
      const sdkAdb = '/Users/dev/Library/Android/sdk/platform-tools/adb';
      final locator = buildLocator(mac, existingFiles: {sdkAdb});

      expect(await locator.locate(), sdkAdb);
    });

    test('falls back to bare adb when it runs from PATH', () async {
      stubWhich(ProcessResult(0, 1, '', ''));
      when(() => executor.run('adb', ['version'])).thenAnswer(
        (_) async => ProcessResult(0, 0, 'Android Debug Bridge', ''),
      );

      expect(await buildLocator(mac).locate(), 'adb');
    });

    test(
      'reports probe failures and returns null when nothing works',
      () async {
        when(() => executor.run(any(), any()))
            .thenThrow(const ProcessException('which', ['adb'], 'missing'));

        expect(await buildLocator(mac).locate(), isNull);
        expect(probeFailures, ['/usr/bin/which adb', 'adb version']);
      },
    );
  });

  group('AdbBinaryLocator on Windows', () {
    final windows = toolchainFor(HostOs.windows, {
      'USERPROFILE': r'C:\Users\dev',
      'LOCALAPPDATA': r'C:\Users\dev\AppData\Local',
    });

    test('takes the first match from CRLF where output', () async {
      when(() => executor.run('where', ['adb.exe'])).thenAnswer(
        (_) async => ProcessResult(
          0,
          0,
          'C:\\tools\\adb.exe\r\nC:\\old\\adb.exe\r\n',
          '',
        ),
      );
      final locator = buildLocator(
        windows,
        existingFiles: {r'C:\tools\adb.exe'},
      );

      expect(await locator.locate(), r'C:\tools\adb.exe');
    });

    test('finds adb.exe in the LOCALAPPDATA SDK', () async {
      when(() => executor.run('where', ['adb.exe']))
          .thenAnswer((_) async => ProcessResult(0, 1, '', 'INFO: not found'));
      const sdkAdb =
          r'C:\Users\dev\AppData\Local\Android\Sdk\platform-tools\adb.exe';

      expect(
        await buildLocator(windows, existingFiles: {sdkAdb}).locate(),
        sdkAdb,
      );
    });
  });
}
