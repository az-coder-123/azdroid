import 'dart:io';

import 'package:desk_droid/core/platform/file_launcher/host_file_launcher.dart';
import 'package:desk_droid/core/platform/file_launcher/mac_host_file_launcher.dart';
import 'package:desk_droid/core/platform/file_launcher/windows_host_file_launcher.dart';
import 'package:desk_droid/core/services/process_executor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProcessExecutor extends Mock implements ProcessExecutor {}

/// Expected command line for each action, per implementation.
class _LauncherSpec {
  const _LauncherSpec({
    required this.name,
    required this.build,
    required this.executable,
    required this.openArgs,
    required this.revealArgs,
  });

  final String name;
  final HostFileLauncher Function(ProcessExecutor) build;
  final String executable;
  final List<String> Function(String path) openArgs;
  final List<String> Function(String path) revealArgs;
}

final _specs = [
  _LauncherSpec(
    name: 'MacHostFileLauncher',
    build: (e) => MacHostFileLauncher(processExecutor: e),
    executable: '/usr/bin/open',
    openArgs: (p) => [p],
    revealArgs: (p) => ['-R', p],
  ),
  _LauncherSpec(
    name: 'WindowsHostFileLauncher',
    build: (e) => WindowsHostFileLauncher(processExecutor: e),
    executable: 'explorer.exe',
    openArgs: (p) => [p],
    revealArgs: (p) => ['/select,$p'],
  ),
];

void main() {
  const path = '/Users/dev/Desktop/shot.png';
  late MockProcessExecutor executor;

  setUp(() => executor = MockProcessExecutor());

  // Shared contract: every implementation must pass the same tests.
  for (final spec in _specs) {
    group('${spec.name} contract', () {
      test('open runs the shell with the path', () async {
        when(() => executor.run(spec.executable, spec.openArgs(path)))
            .thenAnswer((_) async => ProcessResult(1, 0, '', ''));

        expect(await spec.build(executor).open(path), isTrue);
      });

      test('reveal selects the file in the file manager', () async {
        when(() => executor.run(spec.executable, spec.revealArgs(path)))
            .thenAnswer((_) async => ProcessResult(1, 0, '', ''));

        expect(await spec.build(executor).reveal(path), isTrue);
      });

      test('returns false when the process cannot start', () async {
        when(() => executor.run(any(), any()))
            .thenThrow(const ProcessException('shell', [], 'denied'));

        expect(await spec.build(executor).reveal(path), isFalse);
      });
    });
  }

  test('Mac launcher reports a non-zero exit code as failure', () async {
    when(() => executor.run(any(), any()))
        .thenAnswer((_) async => ProcessResult(1, 1, '', 'no such file'));

    expect(
      await MacHostFileLauncher(processExecutor: executor).open(path),
      isFalse,
    );
  });

  test('Windows launcher ignores explorer.exe exit code 1', () async {
    when(() => executor.run(any(), any()))
        .thenAnswer((_) async => ProcessResult(1, 1, '', ''));

    expect(
      await WindowsHostFileLauncher(processExecutor: executor).open(path),
      isTrue,
    );
  });
}
