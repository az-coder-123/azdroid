import 'package:desk_droid/features/mcp/data/handlers/mcp_app_device_tool_executor.dart';
import 'package:desk_droid/features/mcp/data/handlers/mcp_automation_tool_executor.dart';
import 'package:desk_droid/features/mcp/data/handlers/mcp_basic_tool_executor.dart';
import 'package:desk_droid/features/mcp/data/handlers/mcp_device_control_tool_executor.dart';
import 'package:desk_droid/features/mcp/data/handlers/mcp_gesture_tool_executor.dart';
import 'package:desk_droid/features/mcp/data/handlers/mcp_performance_media_tool_executor.dart';
import 'package:desk_droid/features/mcp/data/handlers/mcp_screen_tool_executor.dart';
import 'package:desk_droid/features/mcp/data/handlers/mcp_semantic_system_tool_executor.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_activity_recorder.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_adb_client.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_unsupported_exception.dart';
import 'package:desk_droid/features/mcp/data/utils/mcp_argument_helper.dart';
import 'package:desk_droid/features/mcp/domain/entities/mcp_tool_definition.dart';

/// Top-level coordinator that routes and executes MCP tool calls against
/// Android devices, and reports each call to an [McpActivitySink].
class McpToolExecutor {
  McpToolExecutor({McpAdbClient? adbClient, McpActivitySink? activity})
    : _adb = adbClient ?? McpAdbClient(),
      _activity = activity ?? const NoopMcpActivitySink(),
      _screen = McpScreenToolExecutor(adbClient ?? McpAdbClient()),
      _gesture = McpGestureToolExecutor(adbClient ?? McpAdbClient()),
      _basic = McpBasicToolExecutor(adbClient ?? McpAdbClient()),
      _appDevice = McpAppDeviceToolExecutor(adbClient ?? McpAdbClient()),
      _semantic = McpSemanticSystemToolExecutor(adbClient ?? McpAdbClient()),
      _perfMedia = McpPerformanceMediaToolExecutor(adbClient ?? McpAdbClient()),
      _automation = McpAutomationToolExecutor(adbClient ?? McpAdbClient()),
      _deviceControl = McpDeviceControlToolExecutor(
        adbClient ?? McpAdbClient(),
      );

  static const String _listDevicesTool = 'android_list_devices';

  /// Whether [toolName] maps to a known executor route in this server.
  ///
  /// Mirrors the routing table used by [execute] so guard tests can verify
  /// every published tool actually has an implementation.
  bool canHandle(String toolName) =>
      toolName == _listDevicesTool ||
      _screen.canHandle(toolName) ||
      _gesture.canHandle(toolName) ||
      _basic.canHandle(toolName) ||
      _appDevice.canHandle(toolName) ||
      _semantic.canHandle(toolName) ||
      _perfMedia.canHandle(toolName) ||
      _automation.canHandle(toolName) ||
      _deviceControl.canHandle(toolName);

  final McpAdbClient _adb;
  final McpActivitySink _activity;
  final McpScreenToolExecutor _screen;
  final McpGestureToolExecutor _gesture;
  final McpBasicToolExecutor _basic;
  final McpAppDeviceToolExecutor _appDevice;
  final McpSemanticSystemToolExecutor _semantic;
  final McpPerformanceMediaToolExecutor _perfMedia;
  final McpAutomationToolExecutor _automation;
  final McpDeviceControlToolExecutor _deviceControl;

  /// The serial to act on: the one given, or the only connected device.
  ///
  /// With several devices and no serial it refuses instead of picking one,
  /// so an agent never acts on the wrong phone.
  Future<String?> _resolveDevice(String? providedSerial) async {
    if (providedSerial != null && providedSerial.trim().isNotEmpty) {
      return providedSerial.trim();
    }
    final serials = await _adb.getConnectedSerials();
    if (serials.length > 1) {
      throw McpArgumentException(
        'Several devices are connected (${serials.join(', ')}); pass '
        'deviceSerial to choose one (see android_list_devices).',
      );
    }
    return serials.firstOrNull;
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
    } on McpArgumentException catch (e) {
      result = McpToolResult.error(e.message);
    } on McpUnsupportedOnDeviceException catch (e) {
      result = McpToolResult.error(e.message);
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
    if (_screen.canHandle(toolName)) {
      return _screen.execute(toolName, serial, arguments);
    }
    if (_gesture.canHandle(toolName)) {
      return _gesture.execute(toolName, serial, arguments);
    }
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
    if (_deviceControl.canHandle(toolName)) {
      return _deviceControl.execute(toolName, serial, arguments);
    }
    return Future.value(McpToolResult.error('Unknown tool: $toolName'));
  }
}
