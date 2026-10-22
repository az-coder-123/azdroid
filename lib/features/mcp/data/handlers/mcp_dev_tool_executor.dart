import 'package:desk_droid/features/mcp/data/services/mcp_adb_client.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_app_start_ops.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_display_config_ops.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_frame_rate_ops.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_instrumentation_ops.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_unsupported_exception.dart';
import 'package:desk_droid/features/mcp/data/utils/mcp_argument_helper.dart';
import 'package:desk_droid/features/mcp/domain/entities/mcp_tool_definition.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_thermal_report.dart';

/// Operations for building and checking an app or game: its own logs,
/// launch time, frame rate, device heat, its tests, and display settings.
class McpDevToolExecutor {
  McpDevToolExecutor(this._adb)
    : _frames = McpFrameRateOps(_adb),
      _appStart = McpAppStartOps(_adb),
      _tests = McpInstrumentationOps(_adb),
      _display = McpDisplayConfigOps(_adb);

  final McpAdbClient _adb;
  final McpFrameRateOps _frames;
  final McpAppStartOps _appStart;
  final McpInstrumentationOps _tests;
  final McpDisplayConfigOps _display;

  static const Set<String> operations = {
    'android_get_app_logcat',
    'android_get_frame_rate',
    'android_get_thermal',
    'android_measure_app_start',
    'android_run_instrumentation',
    'android_set_display_config',
  };

  bool canHandle(String toolName) => operations.contains(toolName);

  Future<McpToolResult> execute(
    String toolName,
    String serial,
    Map<String, dynamic> arguments,
  ) async {
    switch (toolName) {
      case 'android_get_app_logcat':
        return _appLogcat(serial, arguments);

      case 'android_get_frame_rate':
        final package =
            arguments.getString('package', aliases: ['pkg']) ??
            (await _adb.getCurrentApp(serial))?['package'];
        if (package == null) {
          return McpToolResult.error('No foreground app; pass package.');
        }
        final durationMs = arguments.getInt('durationMs', defaultValue: 2000);
        final (:layer, :stats) = await _frames.measure(
          serial,
          package,
          durationMs: durationMs,
        );
        return McpToolResult.text(
          'Frame rate of $package (window "$layer", '
          '${durationMs > 0 ? 'last ${durationMs}ms' : 'recent frames'}):\n'
          '• fps while drawing: ${stats.fps.toStringAsFixed(1)} '
          '(display ${stats.refreshRateHz.toStringAsFixed(0)} Hz)\n'
          '• frames: ${stats.frameCount}, drawing time '
          '${stats.renderingMs.toStringAsFixed(0)} ms\n'
          '• slow frames (missed a refresh): ${stats.slowFrames}\n'
          '• frame time p95 ${stats.p95FrameMs.toStringAsFixed(1)} ms, '
          'max ${stats.maxFrameMs.toStringAsFixed(1)} ms'
          '${stats.frameCount < 2 ? '\nNothing was drawn: the screen was '
                    'static. Interact (or let the game run) while measuring.' : ''}',
        );

      case 'android_get_thermal':
        final res = await _adb.run([
          '-s',
          serial,
          'shell',
          'dumpsys',
          'thermalservice',
        ]);
        final report = McpThermalReport.summarize(res.stdout.toString());
        return report == null
            ? McpToolResult.error('This device reports no thermal status.')
            : McpToolResult.text(report);

      case 'android_measure_app_start':
        return McpToolResult.text(
          await _appStart.measure(
            serial,
            arguments.getRequiredString('package', aliases: ['pkg']),
            cold: arguments.getBool('coldStart', defaultValue: true),
          ),
        );

      case 'android_run_instrumentation':
        final report = await _tests.run(
          serial,
          arguments.getRequiredString('package', aliases: ['pkg']),
          runner: arguments.getString('runner'),
          testClass: arguments.getString('testClass', aliases: ['class']),
          timeoutSec: arguments.getInt(
            'timeoutSec',
            defaultValue: McpInstrumentationOps.defaultTimeoutSec,
          ),
        );
        return report.succeeded
            ? McpToolResult.text(report.summarize())
            : McpToolResult.error(report.summarize());

      case 'android_set_display_config':
        return McpToolResult.text(
          await _display.apply(
            serial,
            nightMode: arguments.getString('nightMode')?.toLowerCase(),
            fontScale: arguments.getOptionalDouble('fontScale'),
            density: arguments.getString('density'),
            size: arguments.getString('size'),
            reset: arguments.getBool('reset', defaultValue: false),
          ),
        );

      default:
        return McpToolResult.error('Unknown tool: $toolName');
    }
  }

  Future<McpToolResult> _appLogcat(
    String serial,
    Map<String, dynamic> arguments,
  ) async {
    final package = arguments.getString('package', aliases: ['pkg']);
    int? pid;
    if (package != null) {
      pid = await McpAdbCmdOps.pidOf(_adb, serial, package);
      if (pid == null) {
        throw McpUnsupportedOnDeviceException(
          '$package is not running, so it has no process to read logs from. '
          'Launch it first, or use crashesOnly: true to read its last crash.',
        );
      }
    }
    final sinceSeconds = arguments.getOptionalInt('sinceSeconds');
    int? since;
    if (sinceSeconds != null) {
      final now = await McpAdbCmdOps.deviceEpochSeconds(_adb, serial);
      if (now != null) since = now - sinceSeconds;
    }
    final limit = arguments.getInt('limit', defaultValue: 50);
    final logs = await _adb.getLogcat(
      serial,
      tag: arguments.getString('tag'),
      level: arguments.getString('level', aliases: ['priority']),
      limit: limit,
      pid: pid,
      sinceEpochSeconds: since,
    );
    final scope = [
      if (package != null) '$package (pid $pid)',
      if (sinceSeconds != null) 'last ${sinceSeconds}s',
    ].join(', ');
    return McpToolResult.text(
      'Logcat for $scope (up to $limit lines):\n'
      '${logs.isEmpty ? '(no lines)' : logs}',
    );
  }
}
