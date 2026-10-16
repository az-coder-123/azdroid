import 'package:desk_droid/features/mcp/domain/entities/mcp_tool_definition.dart';

/// Catalog of app lifecycle, clipboard, device metrics, and file transfer tools for MCP.
class McpAppDeviceTools {
  const McpAppDeviceTools._();

  static List<McpToolDefinition> get tools => const [
    McpToolDefinition(
      name: 'android_get_current_app',
      description: 'Returns the package name and active Activity of the application currently focused on the screen.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'deviceSerial': {
            'type': 'string',
            'description': 'Target device serial.',
          },
        },
      },
    ),
    McpToolDefinition(
      name: 'android_launch_app',
      description: 'Launches an application by package name using the default launcher activity.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'deviceSerial': {
            'type': 'string',
            'description': 'Target device serial.',
          },
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
      description: 'Force terminates a running application by package name.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'deviceSerial': {
            'type': 'string',
            'description': 'Target device serial.',
          },
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
      description: 'Clears all user data and cache for an application (resets it to fresh install state).',
      inputSchema: {
        'type': 'object',
        'properties': {
          'deviceSerial': {
            'type': 'string',
            'description': 'Target device serial.',
          },
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
      description: 'Lists packages installed on the device with optional third-party filter and search query.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'deviceSerial': {
            'type': 'string',
            'description': 'Target device serial.',
          },
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
      description: 'Retrieves the text currently stored in the Android system clipboard.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'deviceSerial': {
            'type': 'string',
            'description': 'Target device serial.',
          },
        },
      },
    ),
    McpToolDefinition(
      name: 'android_set_clipboard',
      description: 'Sets text directly into the Android system clipboard.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'deviceSerial': {
            'type': 'string',
            'description': 'Target device serial.',
          },
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
      description: 'Returns hardware model, Android OS version, API level, screen resolution, density, and battery percentage.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'deviceSerial': {
            'type': 'string',
            'description': 'Target device serial.',
          },
        },
      },
    ),
    McpToolDefinition(
      name: 'android_push_file',
      description: 'Uploads a local file from the Mac host to the Android device (e.g. to /sdcard/Download/).',
      inputSchema: {
        'type': 'object',
        'properties': {
          'deviceSerial': {
            'type': 'string',
            'description': 'Target device serial.',
          },
          'localPath': {
            'type': 'string',
            'description': 'Absolute path to file on Mac host.',
          },
          'remotePath': {
            'type': 'string',
            'description': 'Target absolute destination path on Android (default /sdcard/Download/).',
          },
        },
        'required': ['localPath', 'remotePath'],
      },
    ),
    McpToolDefinition(
      name: 'android_pull_file',
      description: 'Downloads a file from the Android device to the Mac host filesystem.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'deviceSerial': {
            'type': 'string',
            'description': 'Target device serial.',
          },
          'remotePath': {
            'type': 'string',
            'description': 'Absolute file path on Android.',
          },
          'localPath': {
            'type': 'string',
            'description': 'Target absolute destination path on Mac host.',
          },
        },
        'required': ['remotePath', 'localPath'],
      },
    ),
  ];
}
