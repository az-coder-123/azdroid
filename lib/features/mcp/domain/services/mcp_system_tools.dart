import 'package:desk_droid/features/mcp/domain/entities/mcp_tool_definition.dart';

/// MCP tool definitions for Android system controls, radios, audio, and permissions.
final List<McpToolDefinition> mcpSystemTools = [
  const McpToolDefinition(
    name: 'android_toggle_wifi',
    description: 'Enables or disables the device Wi-Fi radio.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': {
          'type': 'string',
          'description': 'Target device serial.',
        },
        'enable': {
          'type': 'boolean',
          'description': 'True to enable Wi-Fi, false to disable.',
        },
      },
      'required': ['enable'],
    },
  ),
  const McpToolDefinition(
    name: 'android_toggle_airplane_mode',
    description: 'Enables or disables device Airplane mode.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': {
          'type': 'string',
          'description': 'Target device serial.',
        },
        'enable': {
          'type': 'boolean',
          'description': 'True to enable Airplane mode, false to disable.',
        },
      },
      'required': ['enable'],
    },
  ),
  const McpToolDefinition(
    name: 'android_grant_permission',
    description:
        'Grants a runtime Android permission to an installed application.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': {
          'type': 'string',
          'description': 'Target device serial.',
        },
        'package': {
          'type': 'string',
          'description': 'Application package name (e.g., com.example.app).',
        },
        'permission': {
          'type': 'string',
          'description': 'Android permission string (e.g., android.permission.POST_NOTIFICATIONS, android.permission.CAMERA).',
        },
      },
      'required': ['package', 'permission'],
    },
  ),
  const McpToolDefinition(
    name: 'android_revoke_permission',
    description:
        'Revokes a runtime Android permission from an installed application.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': {
          'type': 'string',
          'description': 'Target device serial.',
        },
        'package': {
          'type': 'string',
          'description': 'Application package name.',
        },
        'permission': {
          'type': 'string',
          'description': 'Android permission string to revoke.',
        },
      },
      'required': ['package', 'permission'],
    },
  ),
  const McpToolDefinition(
    name: 'android_set_volume',
    description: 'Adjusts audio volume level (stream: 1=System, 2=Ring, 3=Music/Media, 4=Alarm, 5=Notification).',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': {
          'type': 'string',
          'description': 'Target device serial.',
        },
        'stream': {
          'type': 'integer',
          'description': 'Audio stream type (1=System, 2=Ring, 3=Music/Media, 4=Alarm, 5=Notification). Default 3.',
        },
        'volumeIndex': {
          'type': 'integer',
          'description': 'Volume index level (typically 0 to 15 or 25).',
        },
      },
      'required': ['volumeIndex'],
    },
  ),
  const McpToolDefinition(
    name: 'android_wake_screen',
    description: 'Wakes up the device screen or puts it into sleep mode.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': {
          'type': 'string',
          'description': 'Target device serial.',
        },
        'wake': {
          'type': 'boolean',
          'description':
              'True to wake screen up, false to put device into sleep mode.',
        },
      },
      'required': ['wake'],
    },
  ),
  const McpToolDefinition(
    name: 'android_open_settings',
    description: 'Opens specific Android system settings (Wi-Fi, Bluetooth, Developer Options) or App Info details.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': {
          'type': 'string',
          'description': 'Target device serial.',
        },
        'action': {
          'type': 'string',
          'description': 'Settings action (e.g., android.settings.WIFI_SETTINGS, android.settings.BLUETOOTH_SETTINGS, android.settings.SETTINGS).',
        },
        'package': {
          'type': 'string',
          'description':
              'Optional package name to open Application Details directly.',
        },
      },
    },
  ),
];
