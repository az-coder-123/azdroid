import 'package:desk_droid/features/mcp/data/handlers/mcp_app_device_tool_executor.dart';
import 'package:desk_droid/features/mcp/data/handlers/mcp_basic_tool_executor.dart';
import 'package:desk_droid/features/mcp/data/handlers/mcp_performance_media_tool_executor.dart';
import 'package:desk_droid/features/mcp/data/handlers/mcp_semantic_system_tool_executor.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_adb_client.dart';
import 'package:desk_droid/features/mcp/domain/entities/mcp_tool_definition.dart';

/// Top-level coordinator that routes and executes MCP tool calls against Android devices.
class McpToolExecutor {
  McpToolExecutor({McpAdbClient? adbClient})
    : _adb = adbClient ?? McpAdbClient(),
      _basic = McpBasicToolExecutor(adbClient ?? McpAdbClient()),
      _appDevice = McpAppDeviceToolExecutor(adbClient ?? McpAdbClient()),
      _semantic = McpSemanticSystemToolExecutor(adbClient ?? McpAdbClient()),
      _perfMedia = McpPerformanceMediaToolExecutor(adbClient ?? McpAdbClient());

  final McpAdbClient _adb;
  final McpBasicToolExecutor _basic;
  final McpAppDeviceToolExecutor _appDevice;
  final McpSemanticSystemToolExecutor _semantic;
  final McpPerformanceMediaToolExecutor _perfMedia;

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
    try {
      if (toolName == 'android_list_devices') {
        final raw = await _adb.listDevicesRaw();
        return raw.isNotEmpty
            ? McpToolResult.text('Attached Android Devices:\n$raw')
            : McpToolResult.text(
                'No attached Android devices detected via ADB.',
              );
      }

      final serial = await _resolveDevice(arguments['deviceSerial'] as String?);
      if (serial == null) {
        return McpToolResult.error(
          'No connected Android device found via ADB.',
        );
      }

      if (_basic.canHandle(toolName)) {
        return await _basic.execute(toolName, serial, arguments);
      }

      if (_appDevice.canHandle(toolName)) {
        return await _appDevice.execute(toolName, serial, arguments);
      }

      if (_semantic.canHandle(toolName)) {
        return await _semantic.execute(toolName, serial, arguments);
      }

      if (_perfMedia.canHandle(toolName)) {
        return await _perfMedia.execute(toolName, serial, arguments);
      }

      return McpToolResult.error('Unknown tool: $toolName');
    } catch (e) {
      return McpToolResult.error('Tool execution exception: $e');
    }
  }
}
