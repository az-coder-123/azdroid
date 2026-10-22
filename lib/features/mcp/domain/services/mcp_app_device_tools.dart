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
      description: 'Launches an application by package name using the default launcher activity.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'deviceSerial': mcpDeviceSerialProp,
          'package': {
            'type': 'string',
            'description': 'Package name to launch (e.g., com.example.app).',
          },
        },
        'required': ['package'],
      },
    ),
    McpToolDefinition(
      name: 'android_stop_app',
      annotations: destructiveToolAnnotations,
      description: 'Force terminates a running application by package name.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'deviceSerial': mcpDeviceSerialProp,
          'package': {
            'type': 'string',
            'description': 'Package name to terminate.',
          },
        },
        'required': ['package'],
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
    McpToolDefinition(
      name: 'android_list_packages',
      annotations: readOnlyToolAnnotations,
      description: 'Lists packages installed on the device with optional third-party filter and search query.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'deviceSerial': mcpDeviceSerialProp,
          'thirdPartyOnly': {
            'type': 'boolean',
            'description': 'If true, only lists non-system third-party apps (default true).',
          },
          'query': {
            'type': 'string',
            'description': 'Optional search keyword to filter package names.',
          },
        },
      },
    ),
    McpToolDefinition(
      name: 'android_get_clipboard',
      annotations: readOnlyToolAnnotations,
      description: 'Reads the device clipboard text. Needs the `cmd clipboard` shell command, which many devices lack (the Android 10 and 13 devices tested): then it returns an error saying so.',
      inputSchema: {
        'type': 'object',
        'properties': {'deviceSerial': mcpDeviceSerialProp},
      },
    ),
    McpToolDefinition(
      name: 'android_set_clipboard',
      annotations: stateSetToolAnnotations,
      description: 'Replaces the device clipboard text. Needs the `cmd clipboard` shell command, which many devices lack (the Android 10 and 13 devices tested): then it returns an error saying so.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'deviceSerial': mcpDeviceSerialProp,
          'text': {
            'type': 'string',
            'description': 'Text to copy into clipboard.',
          },
        },
        'required': ['text'],
      },
    ),
    McpToolDefinition(
      name: 'android_get_device_info',
      annotations: readOnlyToolAnnotations,
      description: 'Returns hardware model, Android OS version, API level, screen resolution, density, and battery percentage.',
      inputSchema: {
        'type': 'object',
        'properties': {'deviceSerial': mcpDeviceSerialProp},
      },
    ),
    McpToolDefinition(
      name: 'android_push_file',
      annotations: destructiveStateSetToolAnnotations,
      description: 'Uploads a local file from the computer to the Android device (e.g. to /sdcard/Download/). Overwrites an existing file at remotePath without asking.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'deviceSerial': mcpDeviceSerialProp,
          'localPath': {
            'type': 'string',
            'description': 'Absolute path of the file on the computer.',
          },
          'remotePath': {
            'type': 'string',
            'description': 'Absolute destination path on the device, e.g. /sdcard/Download/photo.jpg.',
          },
        },
        'required': ['localPath', 'remotePath'],
      },
    ),
    McpToolDefinition(
      name: 'android_pull_file',
      annotations: destructiveStateSetToolAnnotations,
      description: 'Downloads a file from the Android device to the computer. Overwrites an existing file at localPath without asking.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'deviceSerial': mcpDeviceSerialProp,
          'remotePath': {
            'type': 'string',
            'description': 'Absolute file path on Android.',
          },
          'localPath': {
            'type': 'string',
            'description': 'Absolute destination path on the computer.',
          },
        },
        'required': ['remotePath', 'localPath'],
      },
    ),
  ];
}
