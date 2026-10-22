import 'package:desk_droid/features/mcp/domain/entities/mcp_tool_definition.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_schema_fragments.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_tool_annotations.dart';

/// MCP tool definitions for Android system controls, radios, audio, and permissions.
final List<McpToolDefinition> mcpSystemTools = [
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
