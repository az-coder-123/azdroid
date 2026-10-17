import 'dart:io';

import 'package:desk_droid/core/services/host_file_launcher.dart';
import 'package:desk_droid/core/services/process_executor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProcessExecutor extends Mock implements ProcessExecutor {}

void main() {
  late MockProcessExecutor executor;
  late MacHostFileLauncher launcher;
  const path = '/Users/dev/Desktop/shot.png';

  setUp(() {
    executor = MockProcessExecutor();
    launcher = MacHostFileLauncher(processExecutor: executor);
  });

  group('MacHostFileLauncher', () {
    test('open runs /usr/bin/open with the file path', () async {
      when(() => executor.run(MacHostFileLauncher.openExecutable, [path]))
          .thenAnswer((_) async => ProcessResult(1, 0, '', ''));

      expect(await launcher.open(path), isTrue);
    });

    test('revealInFinder passes the -R flag', () async {
      when(() => executor.run(MacHostFileLauncher.openExecutable, ['-R', path]))
          .thenAnswer((_) async => ProcessResult(1, 0, '', ''));

      expect(await launcher.revealInFinder(path), isTrue);
    });

    test('returns false on a non-zero exit code', () async {
      when(() => executor.run(any(), any()))
          .thenAnswer((_) async => ProcessResult(1, 1, '', 'no such file'));

      expect(await launcher.open(path), isFalse);
    });

    test('returns false when the process cannot start', () async {
      when(() => executor.run(any(), any()))
          .thenThrow(const ProcessException('open', [], 'denied'));

      expect(await launcher.revealInFinder(path), isFalse);
    });
  });
}
