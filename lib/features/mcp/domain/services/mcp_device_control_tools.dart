import 'package:desk_droid/features/mcp/domain/entities/mcp_tool_definition.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_schema_fragments.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_tool_annotations.dart';

/// Catalog of Notifications, Mock Location, Network Conditioning,
/// and Hardware Button tools for Azdroid MCP.
class McpDeviceControlTools {
  const McpDeviceControlTools._();

  static List<McpToolDefinition> get tools => const [
    McpToolDefinition(
      name: 'android_get_notifications',
      annotations: readOnlyToolAnnotations,
      description: 'Lists notifications in the status bar (package, title, text, and key), optionally filtered by a substring. Includes message previews such as OTP codes.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'filter': {
            'type': 'string',
            'description':
                'Optional substring filter for package, title, or text.',
          },
          'deviceSerial': mcpDeviceSerialProp,
        },
      },
    ),
    McpToolDefinition(
      name: 'android_dismiss_notification',
      annotations: destructiveToolAnnotations,
      description: 'Hides one notification by its key (from android_get_notifications) by snoozing it for hideMinutes (default 60); it reappears afterwards. Needs Android 11+ (`cmd notification snooze`). adb cannot remove or clear all notifications permanently.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'key': {
            'type': 'string',
            'description': 'Notification key from android_get_notifications.',
          },
          'hideMinutes': {
            'type': 'integer',
            'description': 'How long to hide it, in minutes (default 60).',
          },
          'deviceSerial': mcpDeviceSerialProp,
        },
        'required': ['key'],
      },
    ),
    McpToolDefinition(
      name: 'android_set_location',
      annotations: stateSetToolAnnotations,
      description: 'Replaces the device location for every app with latitude/longitude until called again with reset: true (which restores the real location). Emulators: any version. Devices: Android 12+ with location turned on; this tool does not change that setting. Fails with the reason otherwise. After reset, apps may see the last mock fix until the device gets a real one.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'latitude': {
            'type': 'number',
            'description': 'Latitude in degrees (required unless reset).',
          },
          'longitude': {
            'type': 'number',
            'description': 'Longitude in degrees (required unless reset).',
          },
          'reset': {
            'type': 'boolean',
            'description':
                'True to remove the mock location and restore the real one '
                '(latitude/longitude not needed).',
          },
          'deviceSerial': mcpDeviceSerialProp,
        },
      },
    ),
    McpToolDefinition(
      name: 'android_read_shared_prefs',
      annotations: readOnlyToolAnnotations,
      description: 'Reads a SharedPreferences XML file of an app. Needs a debuggable build of the app (`run-as`) or a rooted device; release builds return an error.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'package': {
            'type': 'string',
            'description': 'Target application package name.',
          },
          'fileName': {
            'type': 'string',
            'description':
                'Optional XML file name (defaults to package_preferences.xml).',
          },
          'deviceSerial': mcpDeviceSerialProp,
        },
        'required': ['package'],
      },
    ),
  ];
}
