import 'package:desk_droid/core/extensions/line_split_extension.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_adb_client.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_unsupported_exception.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_instrumentation_report.dart';

/// Runs an app's on-device tests (`am instrument`), so an agent can check
/// its own change instead of judging from screenshots.
class McpInstrumentationOps {
  const McpInstrumentationOps(this._adb);

  final McpAdbClient _adb;

  /// Default limit for a whole run. `am instrument -w` blocks until the
  /// tests finish; the device's `timeout` stops its client (`am
  /// instrument` execs app_process, so the signal reaches it), and adb is
  /// stopped on the computer shortly after as a fallback.
  static const int defaultTimeoutSec = 600;

  /// Runs the tests of [package] with [runner] (found from the installed
  /// test APK when omitted), optionally only [testClass]
  /// (`com.example.LoginTest` or `com.example.LoginTest#signsIn`).
  Future<McpInstrumentationReport> run(
    String serial,
    String package, {
    String? runner,
    String? testClass,
    int timeoutSec = defaultTimeoutSec,
  }) async {
    final component = runner ?? await findRunner(serial, package);
    final res = await _adb.runWithTimeout([
      '-s',
      serial,
      'shell',
      'timeout',
      '$timeoutSec',
      'am',
      'instrument',
      '-w',
      '-r',
      if (testClass != null) ...[
        '-e',
        'class',
        McpAdbTextOps.shellQuote(testClass),
      ],
      McpAdbTextOps.shellQuote(component),
    ], Duration(seconds: timeoutSec + 15));
    final report = McpInstrumentationReport.parse(
      '${res.stdout}\n${res.stderr}',
    );
    if (res.exitCode == 124) {
      report.runError =
          'Stopped after ${timeoutSec}s (timeoutSec); the '
          'results below are the tests that finished.';
    }
    if (report.tests.isEmpty && report.runError == null) {
      report.runError = 'No test results. Output: ${'${res.stdout}'.trim()}';
    }
    return report;
  }

  /// The installed runner whose target is [package], e.g.
  /// `com.example.test/androidx.test.runner.AndroidJUnitRunner`.
  Future<String> findRunner(String serial, String package) async {
    final res = await _adb.run([
      '-s',
      serial,
      'shell',
      'pm',
      'list',
      'instrumentation',
    ]);
    final runners = parseRunners(res.stdout.toString());
    final match = runners[package];
    if (match == null) {
      throw McpUnsupportedOnDeviceException(
        'No test APK for $package is installed (pm list instrumentation'
        '${runners.isEmpty ? ' is empty' : ': ${runners.values.join(', ')}'}). '
        'Install it first, e.g. `./gradlew installDebugAndroidTest`, or pass '
        'runner.',
      );
    }
    return match;
  }

  /// `target package → runner` from `pm list instrumentation`, whose lines
  /// read `instrumentation:<runner> (target=<package>)`.
  static Map<String, String> parseRunners(String output) => {
    for (final m in output.splitLines().map(_runnerLine.firstMatch))
      if (m != null) m[2]!: m[1]!,
  };

  static final RegExp _runnerLine = RegExp(
    r'^instrumentation:(\S+) \(target=([^)]+)\)',
  );
}
