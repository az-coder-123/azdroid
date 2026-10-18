import 'package:desk_droid/core/constants/adb_timeouts.dart';
import 'package:desk_droid/core/constants/scrcpy_server_constants.dart';
import 'package:desk_droid/core/services/app_logger.dart';
import 'package:desk_droid/core/services/process_executor.dart';

/// Waits until the restore process of a previous scrcpy-server has finished.
///
/// With `cleanup=true`, each server starts a restore process that turns the
/// phone screen back on (after "Screen Off") about half a second after the
/// server exits. On a pipeline restart (bitrate or stay-awake change, quick
/// reconnect), DeskDroid turns the screen off again on the new server; an
/// old restore process that runs after that would turn it back on. Waiting
/// for it first keeps the order.
class ScrcpyCleanupWaiter {
  ScrcpyCleanupWaiter({
    ProcessExecutor? processExecutor,
    this.pollInterval = const Duration(milliseconds: 100),
    this.timeout = const Duration(seconds: 3),
  }) : _executor = processExecutor ?? const DefaultProcessExecutor();

  final ProcessExecutor _executor;
  final Duration pollInterval;

  /// Upper bound; another scrcpy client's restore process may run for its
  /// whole session, and it must not block DeskDroid.
  final Duration timeout;

  /// `pgrep` exit code when no process matches.
  static const int _noMatchExitCode = 1;

  /// Bracketing the last character keeps `pgrep -f` from matching the shell
  /// that runs it (its own command line contains the pattern).
  static final String _pattern = () {
    const name = ScrcpyServerConstants.cleanupMainClass;
    const last = name.length - 1;
    return "'${name.substring(0, last)}[${name[last]}]'";
  }();

  /// Returns when no restore process runs on [deviceSerial], or after
  /// [timeout]. Never throws: a failed check only skips the wait.
  Future<void> waitForIdle({
    required String adbPath,
    required String deviceSerial,
  }) async {
    final stopwatch = Stopwatch()..start();
    while (stopwatch.elapsed < timeout) {
      final result = await _executor.run(adbPath, [
        '-s',
        deviceSerial,
        'shell',
        'pgrep',
        '-f',
        _pattern,
      ], timeout: AdbTimeouts.quickQuery);
      if (result.exitCode == _noMatchExitCode) return;
      if (result.exitCode != 0) {
        AppLogger.debug(
          'Skipping scrcpy cleanup wait on $deviceSerial: '
          'pgrep exited ${result.exitCode} ${result.stderr}',
        );
        return;
      }
      await Future<void>.delayed(pollInterval);
    }
    AppLogger.warning(
      'A scrcpy restore process is still running on $deviceSerial after '
      '${timeout.inSeconds} s; starting anyway',
    );
  }
}
