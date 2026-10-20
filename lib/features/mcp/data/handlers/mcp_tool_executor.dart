import 'package:desk_droid/features/mcp/data/handlers/mcp_app_device_tool_executor.dart';
import 'package:desk_droid/features/mcp/data/handlers/mcp_automation_tool_executor.dart';
import 'package:desk_droid/features/mcp/data/handlers/mcp_basic_tool_executor.dart';
import 'package:desk_droid/features/mcp/data/handlers/mcp_performance_media_tool_executor.dart';
import 'package:desk_droid/features/mcp/data/handlers/mcp_semantic_system_tool_executor.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_activity_recorder.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_adb_client.dart';
import 'package:desk_droid/features/mcp/data/utils/mcp_argument_helper.dart';
import 'package:desk_droid/features/mcp/domain/entities/mcp_tool_definition.dart';

/// Top-level coordinator that routes and executes MCP tool calls against
/// Android devices, and reports each call to an [McpActivitySink].
class McpToolExecutor {
  McpToolExecutor({McpAdbClient? adbClient, McpActivitySink? activity})
    : _adb = adbClient ?? McpAdbClient(),
      _activity = activity ?? const NoopMcpActivitySink(),
      _basic = McpBasicToolExecutor(adbClient ?? McpAdbClient()),
      _appDevice = McpAppDeviceToolExecutor(adbClient ?? McpAdbClient()),
      _semantic = McpSemanticSystemToolExecutor(adbClient ?? McpAdbClient()),
      _perfMedia = McpPerformanceMediaToolExecutor(adbClient ?? McpAdbClient()),
      _automation = McpAutomationToolExecutor(adbClient ?? McpAdbClient());

  static const String _listDevicesTool = 'android_list_devices';

  final McpAdbClient _adb;
  final McpActivitySink _activity;
  final McpBasicToolExecutor _basic;
  final McpAppDeviceToolExecutor _appDevice;
  final McpSemanticSystemToolExecutor _semantic;
  final McpPerformanceMediaToolExecutor _perfMedia;
  final McpAutomationToolExecutor _automation;

  Future<String?> _resolveDevice(String? providedSerial) async {
    if (providedSerial != null && providedSerial.trim().isNotEmpty) {
      return providedSerial.trim();
    }
    final serials = await _adb.getConnectedSerials();
    return serials.isNotEmpty ? serials.first : null;
  }

  /// Dispatches and executes an MCP tool call by name.
  Future<McpToolResult> execute(
    String toolName,
    Map<String, dynamic> arguments,
  ) async {
    final stopwatch = Stopwatch()..start();
    String? serial;
    McpToolResult result;
    try {
      if (toolName == _listDevicesTool) {
        result = await _listDevices();
      } else {
        serial = await _resolveDevice(
          arguments.getString(
            'deviceSerial',
            aliases: ['serial', 'device', 'deviceId'],
          ),
        );
        result = serial == null
            ? McpToolResult.error('No connected Android device found via ADB.')
            : await _route(toolName, serial, arguments);
      }
    } catch (e) {
      result = McpToolResult.error('Tool execution exception: $e');
    }
    _activity.toolCalled(
      tool: toolName,
      deviceSerial: serial,
      succeeded: !result.isError,
      duration: stopwatch.elapsed,
    );
    return result;
  }

  Future<McpToolResult> _listDevices() async {
    final raw = await _adb.listDevicesRaw();
    return raw.isNotEmpty
        ? McpToolResult.text('Attached Android Devices:\n$raw')
        : McpToolResult.text('No attached Android devices detected via ADB.');
  }

  Future<McpToolResult> _route(
    String toolName,
    String serial,
    Map<String, dynamic> arguments,
  ) {
    if (_basic.canHandle(toolName)) {
      return _basic.execute(toolName, serial, arguments);
    }
    if (_appDevice.canHandle(toolName)) {
      return _appDevice.execute(toolName, serial, arguments);
    }
    if (_semantic.canHandle(toolName)) {
      return _semantic.execute(toolName, serial, arguments);
    }
    if (_perfMedia.canHandle(toolName)) {
      return _perfMedia.execute(toolName, serial, arguments);
    }
    if (_automation.canHandle(toolName)) {
      return _automation.execute(toolName, serial, arguments);
    }
    return Future.value(McpToolResult.error('Unknown tool: $toolName'));
  }
}
