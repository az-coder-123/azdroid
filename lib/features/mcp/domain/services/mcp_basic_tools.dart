import 'package:desk_droid/features/mcp/domain/entities/mcp_tool_definition.dart';

/// Catalog of basic input, screen capture, intent, and diagnostic tools for MCP.
class McpBasicTools {
  const McpBasicTools._();

  static List<McpToolDefinition> get tools => const [
    McpToolDefinition(
      name: 'android_list_devices',
      description: 'Lists all connected and discovered Android devices via USB and Wi-Fi.',
      inputSchema: {'type': 'object', 'properties': {}},
    ),
    McpToolDefinition(
      name: 'android_take_screenshot',
      description: 'Captures a high-resolution screenshot from the Android device and returns it as a base64 image artifact.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'deviceSerial': {
            'type': 'string',
            'description': 'Device serial or IP:port (optional if only one device is connected).',
          },
        },
      },
    ),
    McpToolDefinition(
      name: 'android_tap',
      description: 'Simulates a touch tap gesture at normalized coordinates (0.0 to 1.0) on the Android screen.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'deviceSerial': {
            'type': 'string',
            'description': 'Target device serial or IP:port.',
          },
          'x': {
            'type': 'number',
            'description': 'Normalized horizontal coordinate (0.0 to 1.0).',
          },
          'y': {
            'type': 'number',
            'description': 'Normalized vertical coordinate (0.0 to 1.0).',
          },
        },
        'required': ['x', 'y'],
      },
    ),
    McpToolDefinition(
      name: 'android_swipe',
      description: 'Performs a swipe or drag gesture between two coordinates on the Android device.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'deviceSerial': {
            'type': 'string',
            'description': 'Target device serial.',
          },
          'startX': {
            'type': 'number',
            'description': 'Start X normalized coordinate (0.0 to 1.0).',
          },
          'startY': {
            'type': 'number',
            'description': 'Start Y normalized coordinate (0.0 to 1.0).',
          },
          'endX': {
            'type': 'number',
            'description': 'End X normalized coordinate (0.0 to 1.0).',
          },
          'endY': {
            'type': 'number',
            'description': 'End Y normalized coordinate (0.0 to 1.0).',
          },
          'durationMs': {
            'type': 'integer',
            'description':
                'Duration of the swipe in milliseconds (default 300ms).',
          },
        },
        'required': ['startX', 'startY', 'endX', 'endY'],
      },
    ),
    McpToolDefinition(
      name: 'android_type_text',
      description: 'Injects raw or international Unicode text into the currently focused Android input field.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'deviceSerial': {
            'type': 'string',
            'description': 'Target device serial.',
          },
          'text': {
            'type': 'string',
            'description': 'Text to type into the focused field.',
          },
        },
        'required': ['text'],
      },
    ),
    McpToolDefinition(
      name: 'android_press_key',
      description: 'Presses an Android hardware or system navigation key (BACK, HOME, APP_SWITCH, ENTER, TAB, POWER).',
      inputSchema: {
        'type': 'object',
        'properties': {
          'deviceSerial': {
            'type': 'string',
            'description': 'Target device serial.',
          },
          'key': {
            'type': 'string',
            'enum': [
              'BACK',
              'HOME',
              'APP_SWITCH',
              'ENTER',
              'TAB',
              'POWER',
              'VOLUME_UP',
              'VOLUME_DOWN',
            ],
            'description': 'Key name to press.',
          },
        },
        'required': ['key'],
      },
    ),
    McpToolDefinition(
      name: 'android_dispatch_intent',
      description: 'Fires an Android Intent, custom URL scheme, or deep link with optional package and typed extras.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'deviceSerial': {
            'type': 'string',
            'description': 'Target device serial.',
          },
          'action': {
            'type': 'string',
            'description': 'Intent action (e.g., android.intent.action.VIEW).',
          },
          'dataUri': {'type': 'string', 'description': 'Data URI or web URL.'},
          'package': {
            'type': 'string',
            'description': 'Target application package name.',
          },
          'component': {
            'type': 'string',
            'description': 'Explicit target component class.',
          },
          'extras': {
            'type': 'object',
            'description': 'Key-value map of intent extras.',
          },
        },
        'required': ['action'],
      },
    ),
    McpToolDefinition(
      name: 'android_get_logcat',
      description: 'Extracts real-time or recent logcat records from the device with optional tag and level filtering.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'deviceSerial': {
            'type': 'string',
            'description': 'Target device serial.',
          },
          'tag': {'type': 'string', 'description': 'Filter by tag.'},
          'limit': {
            'type': 'integer',
            'description':
                'Maximum number of log lines to retrieve (default 50).',
          },
        },
      },
    ),
    McpToolDefinition(
      name: 'android_install_apk',
      description: 'Sideloads an APK package onto the Android device.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'deviceSerial': {
            'type': 'string',
            'description': 'Target device serial.',
          },
          'apkPath': {
            'type': 'string',
            'description': 'Absolute path to APK on host Mac.',
          },
          'reinstall': {
            'type': 'boolean',
            'description': 'Allow reinstall keeping existing data.',
          },
          'grantPermissions': {
            'type': 'boolean',
            'description': 'Auto-grant runtime permissions.',
          },
        },
        'required': ['apkPath'],
      },
    ),
    McpToolDefinition(
      name: 'android_shell_command',
      description: 'Executes a raw adb shell command on the Android device for advanced troubleshooting.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'deviceSerial': {
            'type': 'string',
            'description': 'Target device serial.',
          },
          'command': {'type': 'string', 'description': 'Shell command string.'},
        },
        'required': ['command'],
      },
    ),
  ];
}
