import 'package:desk_droid/features/mcp/domain/entities/mcp_tool_definition.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_schema_fragments.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_tool_annotations.dart';

/// MCP tool definitions for Android system controls, radios, audio, and permissions.
final List<McpToolDefinition> mcpSystemTools = [
  const McpToolDefinition(
    name: 'android_toggle_wifi',
    annotations: destructiveStateSetToolAnnotations,
    description:
        'Enables or disables the device Wi-Fi radio. Disabling it drops a '
        'Wi-Fi ADB connection, and the device cannot be reached again until '
        'someone re-enables Wi-Fi on it; only use over USB, or confirm first.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': mcpDeviceSerialProp,
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
    annotations: destructiveStateSetToolAnnotations,
    description:
        'Enables or disables device Airplane mode. Enabling it turns the '
        'radios off and drops a Wi-Fi ADB connection; only use over USB, or '
        'confirm first.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': mcpDeviceSerialProp,
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
    annotations: stateSetToolAnnotations,
    description:
        'Grants a runtime Android permission to an installed application.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': mcpDeviceSerialProp,
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
    annotations: destructiveStateSetToolAnnotations,
    description:
        'Revokes a runtime Android permission from an installed application. '
        'Android kills the app process when a granted permission is revoked, '
        'so unsaved app state is lost.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': mcpDeviceSerialProp,
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
    annotations: stateSetToolAnnotations,
    description: 'Adjusts audio volume level (stream: 1=System, 2=Ring, 3=Music/Media, 4=Alarm, 5=Notification).',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': mcpDeviceSerialProp,
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
    annotations: stateSetToolAnnotations,
    description: 'Wakes up the device screen or puts it into sleep mode. Prefer this dedicated tool over android_press_button (wakeup/sleep) for screen power state.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': mcpDeviceSerialProp,
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
    annotations: inputToolAnnotations,
    description: 'Opens specific Android system settings (Wi-Fi, Bluetooth, Developer Options) or App Info details.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': mcpDeviceSerialProp,
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
