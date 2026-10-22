import 'dart:async';
import 'dart:io';

import 'package:desk_droid/core/services/process_output_encoding.dart';

/// adb commands that may block for good.
class McpAdbTimeout {
  const McpAdbTimeout._();

  /// Exit code reported when [run] stops the command (the same
  /// as the `timeout` utility's).
  static const int timedOutExitCode = 124;

  /// Runs [adb] with [args] like `McpAdbClient.run`, but kills it after
  /// [timeout] and returns exit code [timedOutExitCode] with the output so
  /// far.
  ///
  /// A timeout on the device is not enough for commands that run inside
  /// `system_server`: `am start -W` on a locked Redmi 9 (Android 10) kept
  /// the shell's output open after its client process was killed, so adb
  /// never returned.
  static Future<ProcessResult> run(
    String adb,
    List<String> args,
    Duration timeout,
  ) async {
    final process = await Process.start(adb, args);
    final out = process.stdout.transform(adbOutputEncoding.decoder).join();
    final err = process.stderr.transform(adbOutputEncoding.decoder).join();
    final code = await process.exitCode.timeout(
      timeout,
      onTimeout: () {
        process.kill();
        return timedOutExitCode;
      },
    );
    return ProcessResult(
      process.pid,
      code,
      await out.timeout(const Duration(seconds: 2), onTimeout: () => ''),
      await err.timeout(const Duration(seconds: 2), onTimeout: () => ''),
    );
  }
}
