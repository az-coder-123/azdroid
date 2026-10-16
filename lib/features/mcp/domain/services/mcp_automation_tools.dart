import 'package:desk_droid/features/mcp/domain/entities/mcp_tool_definition.dart';

/// Catalog of Smart Waiting, Macro Batching, Notifications, Mock Location,
/// Network Conditioning, and Button simulation tools for MCP.
class McpAutomationTools {
  const McpAutomationTools._();

  static List<McpToolDefinition> get tools => const [
    McpToolDefinition(
      name: 'android_wait_for_element',
      description: 'Polls the UI hierarchy until an element matching text, resourceId, or contentDesc appears, avoiding unnecessary LLM round-trips.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'text': {'type': 'string', 'description': 'Target text to match.'},
          'resourceId': {
            'type': 'string',
            'description': 'Target resource ID to match.',
          },
          'contentDesc': {
            'type': 'string',
            'description': 'Target content-desc to match.',
          },
          'timeoutMs': {
            'type': 'integer',
            'description': 'Maximum wait duration in ms (default 10000).',
          },
          'pollIntervalMs': {
            'type': 'integer',
            'description': 'Polling interval in ms (default 500).',
          },
          'deviceSerial': {
            'type': 'string',
            'description': 'Target device serial or IP:port.',
          },
        },
      },
    ),
    McpToolDefinition(
      name: 'android_batch_actions',
      description: 'Executes a sequential compound macro of actions (tap, type, key, swipe, sleep) locally in one shot.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'actions': {
            'type': 'array',
            'description': 'List of action maps: {"action": "tap"|"type"|"key"|"swipe"|"sleep", ...}',
            'items': {'type': 'object'},
          },
          'deviceSerial': {
            'type': 'string',
            'description': 'Target device serial or IP:port.',
          },
        },
        'required': ['actions'],
      },
    ),
    McpToolDefinition(
      name: 'android_get_notifications',
      description: 'Extracts active system notifications and status bar alerts including 2FA SMS and OTP codes.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'filter': {
            'type': 'string',
            'description':
                'Optional substring filter for package, title, or text.',
          },
          'deviceSerial': {
            'type': 'string',
            'description': 'Target device serial.',
          },
        },
      },
    ),
    McpToolDefinition(
      name: 'android_dismiss_notification',
      description: 'Dismisses a specific notification by key or clears all notifications from the status bar.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'key': {
            'type': 'string',
            'description': 'Specific notification key.',
          },
          'clearAll': {
            'type': 'boolean',
            'description': 'Set true to clear all notifications.',
          },
          'deviceSerial': {
            'type': 'string',
            'description': 'Target device serial.',
          },
        },
      },
    ),
    McpToolDefinition(
      name: 'android_set_location',
      description: 'Sets mock GPS coordinates (latitude, longitude, altitude) for geo-fencing and maps QA testing.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'latitude': {'type': 'number', 'description': 'GPS latitude.'},
          'longitude': {'type': 'number', 'description': 'GPS longitude.'},
          'altitude': {
            'type': 'number',
            'description': 'Optional altitude in meters.',
          },
          'deviceSerial': {
            'type': 'string',
            'description': 'Target device serial.',
          },
        },
        'required': ['latitude', 'longitude'],
      },
    ),
    McpToolDefinition(
      name: 'android_set_network_condition',
      description: 'Simulates network connectivity conditions (normal, offline, wifi_only, data_only) for offline mode testing.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'mode': {
            'type': 'string',
            'enum': ['normal', 'offline', 'wifi_only', 'data_only'],
            'description': 'Target network mode.',
          },
          'deviceSerial': {
            'type': 'string',
            'description': 'Target device serial.',
          },
        },
        'required': ['mode'],
      },
    ),
    McpToolDefinition(
      name: 'android_long_press',
      description: 'Performs a long-press touch gesture at normalized coordinates (0.0 to 1.0) with configurable hold duration.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'x': {
            'type': 'number',
            'description': 'Normalized horizontal coordinate (0.0 to 1.0).',
          },
          'y': {
            'type': 'number',
            'description': 'Normalized vertical coordinate (0.0 to 1.0).',
          },
          'durationMs': {
            'type': 'integer',
            'description': 'Press duration in milliseconds (default 1000).',
          },
          'deviceSerial': {
            'type': 'string',
            'description': 'Target device serial.',
          },
        },
        'required': ['x', 'y'],
      },
    ),
    McpToolDefinition(
      name: 'android_open_notification_panel',
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
          'deviceSerial': {
            'type': 'string',
            'description': 'Target device serial.',
          },
        },
      },
    ),
    McpToolDefinition(
      name: 'android_read_shared_prefs',
      description: 'Reads SharedPreferences XML keys and values for deep application state inspection and QA validation.',
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
          'deviceSerial': {
            'type': 'string',
            'description': 'Target device serial.',
          },
        },
        'required': ['package'],
      },
    ),
    McpToolDefinition(
      name: 'android_press_button',
      description: 'Triggers hardware physical buttons (VOLUME_UP, VOLUME_DOWN, CAMERA, MUTE, WAKEUP, SLEEP, MEDIA_PLAY_PAUSE).',
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
          'deviceSerial': {
            'type': 'string',
            'description': 'Target device serial.',
          },
        },
        'required': ['button'],
      },
    ),
  ];
}
