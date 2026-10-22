import 'package:desk_droid/core/extensions/line_split_extension.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_adb_client.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_adb_timeout.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_shell_result.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_unsupported_exception.dart';

/// Launches an app with `am start -W` and reports how long it took to show
/// its first frame.
class McpAppStartOps {
  const McpAppStartOps(this._adb);

  final McpAdbClient _adb;

  /// `am start -W` waits for the first frame and never returns when the
  /// activity cannot show (on a locked Redmi 9 it hung indefinitely); it
  /// runs inside system_server, so only stopping adb on the computer ends
  /// it ([McpAdbClient.runWithTimeout]).
  static const int launchTimeoutSec = 30;

  /// Launches [package]'s launcher activity; [cold] force-stops it first so
  /// the measurement includes process start.
  Future<String> measure(
    String serial,
    String package, {
    bool cold = true,
  }) async {
    final component = await launcherActivity(serial, package);
    if (cold) {
      await _adb.run(['-s', serial, 'shell', 'am', 'force-stop', package]);
    }
    final res = await _adb.runWithTimeout([
      '-s',
      serial,
      'shell',
      'am',
      'start',
      '-W',
      '-n',
      component,
    ], const Duration(seconds: launchTimeoutSec));
    final out = res.stdout.toString();
    if (res.exitCode == McpAdbTimeout.timedOutExitCode) {
      throw McpUnsupportedOnDeviceException(
        '$component showed no frame within ${launchTimeoutSec}s. Is the '
        'screen locked or off? Unlock it and retry.',
      );
    }
    final timing = summarize(out);
    if (!res.succeeded || timing == null) {
      throw McpUnsupportedOnDeviceException(
        'Could not launch $component: ${out.trim()} ${res.stderr}'.trim(),
      );
    }
    return '$component (${cold ? 'cold start requested' : 'as running'}):\n'
        '$timing';
  }

  /// `package/activity` of the launcher entry.
  Future<String> launcherActivity(String serial, String package) async {
    final res = await _adb.run([
      '-s',
      serial,
      'shell',
      'cmd',
      'package',
      'resolve-activity',
      '--brief',
      '-c',
      'android.intent.category.LAUNCHER',
      package,
    ]);
    final component = res.stdout
        .toString()
        .splitLines()
        .map((l) => l.trim())
        .lastWhere((l) => l.startsWith('$package/'), orElse: () => '');
    if (component.isEmpty) {
      throw McpUnsupportedOnDeviceException(
        '$package has no launcher activity (is it installed?).',
      );
    }
    return component;
  }

  /// The timing lines of `am start -W` (`LaunchState`, `TotalTime`,
  /// `WaitTime`), or `null` when it reported none.
  static String? summarize(String output) {
    final fields = <String, String>{};
    for (final line in output.splitLines()) {
      final m = RegExp(r'^\s*(LaunchState|TotalTime|WaitTime|Status): (.+)$')
          .firstMatch(line);
      if (m != null) fields[m[1]!] = m[2]!.trim();
    }
    final total = fields['TotalTime'];
    final wait = fields['WaitTime'];
    if (total == null && wait == null) return null;
    return [
      if (total != null && total != '0')
        '• Time to first frame (TotalTime): $total ms',
      if (wait != null) '• Including system wait (WaitTime): $wait ms',
      if (fields['LaunchState'] case final state?) '• Launch state: $state',
      if (fields['Status'] case final status? when status != 'ok')
        '• Status: $status',
      if (total == null || total == '0')
        'Android reported no first frame: the app was already in front or '
            'its window was reused (seen on Android 13 right after HOME). '
            'Use coldStart: true for a comparable number.',
    ].join('\n');
  }
}
