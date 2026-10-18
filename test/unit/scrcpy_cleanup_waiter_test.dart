import 'dart:io';

import 'package:desk_droid/core/services/process_executor.dart';
import 'package:desk_droid/features/streaming/data/services/scrcpy_cleanup_waiter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockProcessExecutor extends Mock implements ProcessExecutor {}

void main() {
  const adb = '/usr/local/bin/adb';
  const serial = '192.168.1.3:5555';
  late _MockProcessExecutor executor;
  late ScrcpyCleanupWaiter waiter;

  setUp(() {
    executor = _MockProcessExecutor();
    waiter = ScrcpyCleanupWaiter(
      processExecutor: executor,
      pollInterval: Duration.zero,
      timeout: const Duration(milliseconds: 200),
    );
  });

  void answerExitCodes(List<int> codes) {
    final queue = [...codes];
    when(() => executor.run(adb, any(), timeout: any(named: 'timeout')))
        .thenAnswer(
          (_) async => ProcessResult(
            1,
            queue.length > 1 ? queue.removeAt(0) : queue.first,
            '',
            '',
          ),
        );
  }

  List<String> pgrepArgs() =>
      verify(
            () =>
                executor.run(adb, captureAny(), timeout: any(named: 'timeout')),
          ).captured.first
          as List<String>;

  test('returns at once when no restore process runs', () async {
    answerExitCodes([1]);

    await waiter.waitForIdle(adbPath: adb, deviceSerial: serial);

    final args = pgrepArgs();
    expect(args.take(4), ['-s', serial, 'shell', 'pgrep']);
    // The bracket keeps pgrep from matching its own shell.
    expect(args.last, "'com.genymobile.scrcpy.CleanU[p]'");
  });

  test('polls until the restore process is gone', () async {
    answerExitCodes([0, 0, 1]);

    await waiter.waitForIdle(adbPath: adb, deviceSerial: serial);

    verify(() => executor.run(adb, any(), timeout: any(named: 'timeout')))
        .called(3);
  });

  test('skips the wait when pgrep itself fails', () async {
    answerExitCodes([127]);

    await waiter.waitForIdle(adbPath: adb, deviceSerial: serial);

    verify(() => executor.run(adb, any(), timeout: any(named: 'timeout')))
        .called(1);
  });

  test('gives up after the timeout', () async {
    answerExitCodes([0]);
    final stopwatch = Stopwatch()..start();

    await waiter.waitForIdle(adbPath: adb, deviceSerial: serial);

    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 2)));
  });
}
