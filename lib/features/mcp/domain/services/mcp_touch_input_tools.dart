import 'package:desk_droid/features/mcp/domain/entities/mcp_tool_definition.dart';

/// Catalog of touch gestures, text entry, and basic hardware input tools for MCP.
final List<McpToolDefinition> mcpTouchInputTools = [
  const McpToolDefinition(
    name: 'android_pinch_gesture',
    description: 'Executes a two-finger pinch gesture (zoom in / zoom out) centered at specified normalized or pixel coordinates.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'scale': {
          'type': 'number',
          'description': 'Scale factor (> 1.0 to zoom in, e.g. 1.5; < 1.0 to zoom out, e.g. 0.5). Alias: scaleFactor.',
        },
        'scaleFactor': {
          'type': 'number',
          'description':
              'Alias for scale (> 1.0 to zoom in, < 1.0 to zoom out).',
        },
        'centerX': {
          'type': 'number',
          'description': 'Horizontal center (0.0..1.0 or pixels, default 0.5).',
        },
        'centerY': {
          'type': 'number',
          'description': 'Vertical center (0.0..1.0 or pixels, default 0.5).',
        },
        'durationMs': {
          'type': 'integer',
          'description': 'Gesture duration in milliseconds (default 400).',
        },
        'deviceSerial': {
          'type': 'string',
          'description': 'Target device serial or IP:port.',
        },
      },
      'required': ['scale'],
    },
  ),
  const McpToolDefinition(
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
  const McpToolDefinition(
    name: 'android_double_tap',
    description: 'Executes a rapid double-tap gesture within the native Android double-tap window (default 120ms) to seek video (+10s/-10s), zoom, or trigger secondary actions.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': {
          'type': 'string',
          'description': 'Target device serial or IP:port.',
        },
        'x': {
          'type': 'number',
          'description': 'X coordinate (normalized 0.0-1.0 or pixels).',
        },
        'y': {
          'type': 'number',
          'description': 'Y coordinate (normalized 0.0-1.0 or pixels).',
        },
        'intervalMs': {
          'type': 'integer',
          'description': 'Delay between taps in milliseconds (default 120ms).',
        },
      },
      'required': ['x', 'y'],
    },
  ),
  const McpToolDefinition(
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
          'description': 'Duration of the swipe in ms (default 300ms).',
        },
      },
      'required': ['startX', 'startY', 'endX', 'endY'],
    },
  ),
  const McpToolDefinition(
    name: 'android_drag',
    description: 'Performs a smooth, controlled drag gesture between two points (default duration 1000ms) for timeline seekbars, volume sliders, and list reordering.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': {
          'type': 'string',
          'description': 'Target device serial.',
        },
        'startX': {
          'type': 'number',
          'description': 'Start X (normalized 0.0-1.0 or pixels).',
        },
        'startY': {
          'type': 'number',
          'description': 'Start Y (normalized 0.0-1.0 or pixels).',
        },
        'endX': {
          'type': 'number',
          'description': 'End X (normalized 0.0-1.0 or pixels).',
        },
        'endY': {
          'type': 'number',
          'description': 'End Y (normalized 0.0-1.0 or pixels).',
        },
        'durationMs': {
          'type': 'integer',
          'description': 'Drag duration in milliseconds (default 1000ms).',
        },
      },
      'required': ['startX', 'startY', 'endX', 'endY'],
    },
  ),
  const McpToolDefinition(
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
  const McpToolDefinition(
    name: 'android_set_text',
    description: 'Sets exact text into the focused field or target element by ID, bypassing IME predictive autocorrect and Vietnamese Telex alteration.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': {
          'type': 'string',
          'description': 'Target device serial or IP:port.',
        },
        'text': {
          'type': 'string',
          'description': 'Exact text string to insert (supports unicode, spaces, and punctuation).',
        },
        'elementId': {
          'type': 'integer',
          'description': 'Optional target element ID from semantic tree to tap before setting text.',
        },
        'clearFirst': {
          'type': 'boolean',
          'description': 'Whether to clear existing text before inserting (default false).',
        },
      },
      'required': ['text'],
    },
  ),
  const McpToolDefinition(
    name: 'android_clear_text',
    description: 'Clears all existing text in the currently focused input field or target element by ID in a single shot.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': {
          'type': 'string',
          'description': 'Target device serial or IP:port.',
        },
        'elementId': {
          'type': 'integer',
          'description': 'Optional target element ID from semantic tree to tap before clearing.',
        },
      },
    },
  ),
  const McpToolDefinition(
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
];
