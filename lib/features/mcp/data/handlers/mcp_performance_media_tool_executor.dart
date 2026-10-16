import 'package:desk_droid/features/mcp/data/services/mcp_adb_client.dart';
import 'package:desk_droid/features/mcp/domain/entities/mcp_tool_definition.dart';

/// Handler for performance telemetry, screen recording, processes, and orientation tools.
class McpPerformanceMediaToolExecutor {
  const McpPerformanceMediaToolExecutor(this._adb);

  final McpAdbClient _adb;

  bool canHandle(String toolName) {
    return const {
      'android_get_cpu_usage',
      'android_get_memory_info',
      'android_get_battery_stats',
      'android_get_gfx_info',
      'android_get_network_info',
      'android_record_screen',
      'android_list_processes',
      'android_kill_process',
      'android_set_orientation',
      'android_simulate_biometric',
    }.contains(toolName);
  }

  Future<McpToolResult> execute(
    String toolName,
    String serial,
    Map<String, dynamic> arguments,
  ) async {
    switch (toolName) {
      case 'android_get_cpu_usage':
        final pkg = arguments['package'] as String?;
        final cpu = await _adb.getCpuUsage(serial, package: pkg);
        return McpToolResult.text('CPU Consumption for $serial:\n$cpu');

      case 'android_get_memory_info':
        final pkg = arguments['package'] as String;
        final mem = await _adb.getMemoryInfo(serial, pkg);
        return McpToolResult.text(
          'Memory (PSS/Dalvik/Native) for $pkg on $serial:\n$mem',
        );

      case 'android_get_battery_stats':
        final stats = await _adb.getBatteryStats(serial);
        final buffer = StringBuffer('Battery Diagnostics for $serial:\n');
        stats.forEach((k, v) => buffer.writeln('• $k: $v'));
        return McpToolResult.text(buffer.toString().trim());

      case 'android_get_gfx_info':
        final pkg = arguments['package'] as String;
        final gfx = await _adb.getGfxInfo(serial, pkg);
        return McpToolResult.text(
          'RenderThread Graphics Telemetry for $pkg on $serial:\n$gfx',
        );

      case 'android_get_network_info':
        final net = await _adb.getNetworkInfo(serial);
        final buffer = StringBuffer('Network Telemetry for $serial:\n');
        net.forEach((k, v) => buffer.writeln('• $k: $v'));
        return McpToolResult.text(buffer.toString().trim());

      case 'android_record_screen':
        final dur = arguments['durationSec'] as int? ?? 5;
        final dest = arguments['localDestination'] as String;
        final success = await _adb.recordScreen(
          serial,
          durationSec: dur,
          localDestination: dest,
        );
        return success
            ? McpToolResult.text(
                'Screen recorded ($dur sec) and saved to $dest on Mac host.',
              )
            : McpToolResult.error(
                'Failed to capture screen recording from $serial.',
              );

      case 'android_list_processes':
        final filter = arguments['filter'] as String?;
        final procs = await _adb.listProcesses(serial, filter: filter);
        final lines = procs
            .map((p) => 'PID ${p['pid']}: ${p['name']}')
            .join('\n');
        return McpToolResult.text(
          'Active Processes on $serial (${procs.length}):\n$lines',
        );

      case 'android_kill_process':
        final pid = arguments['pid'] as int?;
        final pkg = arguments['package'] as String?;
        final success = await _adb.killProcess(serial, pid: pid, package: pkg);
        return success
            ? McpToolResult.text('Terminated process ${pid ?? pkg} on $serial.')
            : McpToolResult.error('Failed to terminate process ${pid ?? pkg}.');

      case 'android_set_orientation':
        final orient = arguments['orientation'] as int;
        final success = await _adb.setOrientation(serial, orient);
        final orientNames = [
          'Portrait (0°)',
          'Landscape (90°)',
          'Reverse Portrait (180°)',
          'Reverse Landscape (270°)',
        ];
        return success
            ? McpToolResult.text(
                'Orientation set to ${orientNames[orient.clamp(0, 3)]} on $serial.',
              )
            : McpToolResult.error(
                'Failed to change screen orientation on $serial.',
              );

      case 'android_simulate_biometric':
        final successParam = arguments['success'] as bool? ?? true;
        final success = await _adb.simulateBiometric(
          serial,
          success: successParam,
        );
        return success
            ? McpToolResult.text(
                'Biometric authentication simulation (${successParam ? 'Success' : 'Failure'}) triggered.',
              )
            : McpToolResult.error(
                'Failed to simulate biometric authentication on $serial.',
              );

      default:
        return McpToolResult.error(
          'Unhandled performance/media tool: $toolName',
        );
    }
  }
}
