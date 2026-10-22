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
      name: 'android_set_network_condition',
      annotations: destructiveStateSetToolAnnotations,
      description: 'Simulates network connectivity conditions (normal, offline, wifi_only, data_only) for offline mode testing. "offline" and "data_only" turn Wi-Fi off and drop a Wi-Fi ADB connection; only use them over USB, or confirm first.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'mode': {
            'type': 'string',
            'enum': ['normal', 'offline', 'wifi_only', 'data_only'],
            'description': 'Target network mode.',
          },
          'deviceSerial': mcpDeviceSerialProp,
        },
        'required': ['mode'],
      },
    ),
    McpToolDefinition(
      name: 'android_long_press',
      annotations: inputToolAnnotations,
      description: 'Presses and holds one point for durationMs (default 1000 ms), e.g. to open a context menu. Give the point as x/y, xRatio/yRatio, or xPixel/yPixel (units may be mixed per axis); one form is required.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'x': mcpCoordProp,
          'y': mcpCoordProp,
          'xRatio': mcpCoordRatioProp,
          'yRatio': mcpCoordRatioProp,
          'xPixel': mcpCoordPixelProp,
          'yPixel': mcpCoordPixelProp,
          'durationMs': {
            'type': 'integer',
            'description': 'Press duration in milliseconds (default 1000).',
          },
          'deviceSerial': mcpDeviceSerialProp,
        },
      },
    ),
    McpToolDefinition(
      name: 'android_open_notification_panel',
      annotations: inputToolAnnotations,
      description: 'Expands or collapses the Android notification shade or Quick Settings drawer.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'expand': {
            'type': 'boolean',
            'description': 'True to expand, false to collapse.',
          },
          'quickSettings': {
            'type': 'boolean',
            'description':
                'True to expand Quick Settings instead of notifications.',
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
    McpToolDefinition(
      name: 'android_press_button',
      annotations: inputToolAnnotations,
      description: 'Triggers hardware physical buttons (volume_up, volume_down, camera, mute, wakeup, sleep, media_play_pause, media_next, media_prev). For navigation keys (BACK, HOME, APP_SWITCH) prefer android_press_key.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'button': {
            'type': 'string',
            'enum': [
              'volume_up',
              'volume_down',
              'camera',
              'mute',
              'wakeup',
              'sleep',
              'media_play_pause',
              'media_next',
              'media_prev',
            ],
            'description': 'Target hardware button.',
          },
          'deviceSerial': mcpDeviceSerialProp,
        },
        'required': ['button'],
      },
    ),
  ];
}
