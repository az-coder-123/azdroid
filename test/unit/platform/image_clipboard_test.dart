import 'dart:io';

import 'package:desk_droid/core/platform/image_clipboard/image_clipboard.dart';
import 'package:desk_droid/core/platform/image_clipboard/mac_image_clipboard.dart';
import 'package:desk_droid/core/platform/image_clipboard/windows_image_clipboard.dart';
import 'package:desk_droid/core/services/process_executor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProcessExecutor extends Mock implements ProcessExecutor {}

typedef _Builder = ImageClipboard Function(ProcessExecutor executor);

void main() {
  late MockProcessExecutor executor;

  setUpAll(() => registerFallbackValue(Duration.zero));
  setUp(() => executor = MockProcessExecutor());

  void stubResult(ProcessResult result) {
    when(() => executor.run(any(), any(), timeout: any(named: 'timeout')))
        .thenAnswer((_) async => result);
  }

  final implementations = <String, (_Builder, String)>{
    'MacImageClipboard': (
      (e) => MacImageClipboard(processExecutor: e),
      '/usr/bin/osascript',
    ),
    'WindowsImageClipboard': (
      (e) => WindowsImageClipboard(processExecutor: e),
      'powershell.exe',
    ),
  };

  // Shared contract: every implementation must pass the same tests.
  for (final MapEntry(key: name, value: (build, executable))
      in implementations.entries) {
    group('$name contract', () {
      test('returns true when the copy command succeeds', () async {
        stubResult(ProcessResult(1, 0, '', ''));

        expect(await build(executor).copyPng('/shots/a.png'), isTrue);
        final call = verify(
          () =>
              executor.run(captureAny(), any(), timeout: any(named: 'timeout')),
        ).captured;
        expect(call.single, executable);
      });

      test('returns false on a non-zero exit code', () async {
        stubResult(ProcessResult(1, 1, '', 'error'));

        expect(await build(executor).copyPng('/shots/a.png'), isFalse);
      });

      test('returns false when the process cannot start', () async {
        when(() => executor.run(any(), any(), timeout: any(named: 'timeout')))
            .thenThrow(const ProcessException('x', [], 'missing'));

        expect(await build(executor).copyPng('/shots/a.png'), isFalse);
      });
    });
  }

  test('Mac script escapes quotes and backslashes', () {
    expect(
      MacImageClipboard.scriptFor(r'/tmp/a "b"\c.png'),
      contains(r'POSIX file "/tmp/a \"b\"\\c.png"'),
    );
  });

  test('Windows script escapes single quotes by doubling', () {
    expect(
      WindowsImageClipboard.scriptFor(r"C:\Users\O'Brien\shot.png"),
      contains(r"FromFile('C:\Users\O''Brien\shot.png')"),
    );
  });
}
