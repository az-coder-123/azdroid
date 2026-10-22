import 'package:desk_droid/features/mcp/domain/entities/mcp_tool_definition.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_schema_fragments.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_tool_annotations.dart';

/// Catalog of app lifecycle, clipboard, device metrics, and file transfer tools for MCP.
class McpAppDeviceTools {
  const McpAppDeviceTools._();

  static List<McpToolDefinition> get tools => const [
    McpToolDefinition(
      name: 'android_get_current_app',
      annotations: readOnlyToolAnnotations,
      description: 'Returns the package name and active Activity of the application currently focused on the screen.',
      inputSchema: {
        'type': 'object',
        'properties': {'deviceSerial': mcpDeviceSerialProp},
      },
    ),
    McpToolDefinition(
      name: 'android_launch_app',
      annotations: inputToolAnnotations,
      description: 'Launches an application by package name using the default launcher activity. With measure: true, launches with `am start -W` and returns the time to first frame (cold start by default: force-stops the app first).',
      inputSchema: {
        'type': 'object',
        'properties': {
          'deviceSerial': mcpDeviceSerialProp,
          'package': {
            'type': 'string',
            'description': 'Package name to launch (e.g., com.example.app).',
          },
          'measure': {
            'type': 'boolean',
            'description': 'Report launch time (default false).',
          },
          'coldStart': {
            'type': 'boolean',
            'description':
                'measure: force-stop first to include process start '
                '(default true).',
          },
        },
        'required': ['package'],
      },
    ),
    McpToolDefinition(
      name: 'android_stop_app',
      annotations: destructiveToolAnnotations,
      description: 'Stops an app: with package, force-stops it (unsaved state is lost); with pid, sends `kill`, which works only on processes the adb shell owns unless the device is rooted. Give package or pid.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'deviceSerial': mcpDeviceSerialProp,
          'package': {
            'type': 'string',
            'description': 'Package name to force-stop.',
          },
          'pid': {
            'type': 'integer',
            'description': 'Process ID to kill instead.',
          },
        },
      },
    ),
    McpToolDefinition(
      name: 'android_clear_app_data',
      annotations: destructiveToolAnnotations,
      description: 'Clears all user data and cache for an application (resets it to fresh install state).',
      inputSchema: {
        'type': 'object',
        'properties': {
          'deviceSerial': mcpDeviceSerialProp,
          'package': {
            'type': 'string',
            'description': 'Package name to reset.',
          },
        },
        'required': ['package'],
      },
    ),
  ];
}
