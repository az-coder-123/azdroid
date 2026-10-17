import 'dart:io';

import 'package:desk_droid/core/services/adb_binary_locator.dart';
import 'package:desk_droid/core/services/process_executor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProcessExecutor extends Mock implements ProcessExecutor {}

void main() {
  late MockProcessExecutor executor;
  late List<String> probeFailures;

  setUp(() {
    executor = MockProcessExecutor();
    probeFailures = [];
  });

  AdbBinaryLocator buildLocator({
    Set<String> existingFiles = const {},
    Map<String, String> environment = const {'HOME': '/Users/dev'},
  }) {
    return AdbBinaryLocator(
      executor: executor,
      environment: environment,
      fileExists: (path) async => existingFiles.contains(path),
      onProbeFailure: (probe, _) => probeFailures.add(probe),
    );
  }

  void stubWhich(ProcessResult result) {
    when(() => executor.run(AdbBinaryLocator.whichExecutable, ['adb']))
        .thenAnswer((_) async => result);
  }

  void stubVersion(ProcessResult result) {
    when(() => executor.run('adb', ['version']))
        .thenAnswer((_) async => result);
  }

  group('AdbBinaryLocator', () {
    test('returns path reported by which when the file exists', () async {
      stubWhich(ProcessResult(0, 0, '/opt/homebrew/bin/adb\n', ''));
      final locator = buildLocator(existingFiles: {'/opt/homebrew/bin/adb'});

      expect(await locator.locate(), '/opt/homebrew/bin/adb');
    });

    test('prefers ANDROID_HOME over the default SDK location', () {
      final locator = buildLocator(
        environment: {'HOME': '/Users/dev', 'ANDROID_HOME': '/sdk'},
      );

      expect(locator.candidatePaths.first, '/sdk/platform-tools/adb');
      expect(
        locator.candidatePaths,
        contains('/Users/dev/Library/Android/sdk/platform-tools/adb'),
      );
    });

    test('falls back to known install paths when which fails', () async {
      stubWhich(ProcessResult(0, 1, '', 'not found'));
      final locator = buildLocator(existingFiles: {'/usr/local/bin/adb'});

      expect(await locator.locate(), '/usr/local/bin/adb');
    });

    test('falls back to bare adb when it runs from PATH', () async {
      stubWhich(ProcessResult(0, 1, '', ''));
      stubVersion(ProcessResult(0, 0, 'Android Debug Bridge', ''));

      expect(await buildLocator().locate(), 'adb');
    });

    test(
      'reports probe failures and returns null when nothing works',
      () async {
        when(() => executor.run(any(), any()))
            .thenThrow(const ProcessException('which', ['adb'], 'missing'));

        expect(await buildLocator().locate(), isNull);
        expect(probeFailures, ['which adb', 'adb version']);
      },
    );
  });
}
