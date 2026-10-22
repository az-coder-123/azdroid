import 'package:desk_droid/features/mcp/domain/entities/mcp_tool_definition.dart';

const _serialProp = {
  'type': 'string',
  'description': 'Target device serial or IP:port.',
};

const _coordProp = {
  'type': 'number',
  'description': 'Coordinate (normalized 0.0-1.0 or physical pixels).',
};

const _coordRatioProp = {
  'type': 'number',
  'description': 'Explicit normalized coordinate ratio from 0.0 to 1.0 (screen-relative). Takes precedence over raw x/y.',
};

const _coordPixelProp = {
  'type': 'number',
  'description': 'Explicit physical screen pixel coordinate (integer or float). Takes precedence over raw x/y.',
};

/// Catalog of touch gestures, text entry, and basic hardware input tools for MCP.
final List<McpToolDefinition> mcpTouchInputTools = [
  const McpToolDefinition(
    name: 'android_tap',
    description: 'Simulates a touch tap gesture at normalized coordinates (0.0 to 1.0) or physical pixels on the Android screen.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': _serialProp,
        'x': _coordProp,
        'y': _coordProp,
        'xRatio': _coordRatioProp,
        'yRatio': _coordRatioProp,
        'xPixel': _coordPixelProp,
        'yPixel': _coordPixelProp,
      },
    },
  ),
  const McpToolDefinition(
    name: 'android_double_tap',
    description: 'Executes a rapid double-tap gesture within the native Android double-tap window (default 120ms) to seek video (+10s/-10s), zoom, or trigger secondary actions.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': _serialProp,
        'x': _coordProp,
        'y': _coordProp,
        'xRatio': _coordRatioProp,
        'yRatio': _coordRatioProp,
        'xPixel': _coordPixelProp,
        'yPixel': _coordPixelProp,
        'intervalMs': {
          'type': 'integer',
          'description': 'Delay between taps in milliseconds (default 120ms).',
        },
      },
    },
  ),
  const McpToolDefinition(
    name: 'android_swipe',
    description: 'Performs a swipe or drag gesture between two coordinates on the Android device.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': _serialProp,
        'startX': _coordProp,
        'startY': _coordProp,
        'endX': _coordProp,
        'endY': _coordProp,
        'startXRatio': _coordRatioProp,
        'startYRatio': _coordRatioProp,
        'endXRatio': _coordRatioProp,
        'endYRatio': _coordRatioProp,
        'startXPixel': _coordPixelProp,
        'startYPixel': _coordPixelProp,
        'endXPixel': _coordPixelProp,
        'endYPixel': _coordPixelProp,
        'durationMs': {
          'type': 'integer',
          'description': 'Duration of the swipe in ms (default 300ms).',
        },
      },
    },
  ),
  const McpToolDefinition(
    name: 'android_drag',
    description: 'Performs a smooth, controlled drag gesture between two points (default duration 1000ms) for timeline seekbars, volume sliders, and list reordering.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': _serialProp,
        'startX': _coordProp,
        'startY': _coordProp,
        'endX': _coordProp,
        'endY': _coordProp,
        'startXRatio': _coordRatioProp,
        'startYRatio': _coordRatioProp,
        'endXRatio': _coordRatioProp,
        'endYRatio': _coordRatioProp,
        'startXPixel': _coordPixelProp,
        'startYPixel': _coordPixelProp,
        'endXPixel': _coordPixelProp,
        'endYPixel': _coordPixelProp,
        'durationMs': {
          'type': 'integer',
          'description': 'Drag duration in milliseconds (default 1000ms).',
        },
      },
    },
  ),
  const McpToolDefinition(
    name: 'android_type_text',
    description: 'Injects raw or international Unicode text into the currently focused Android input field.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': _serialProp,
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
        'deviceSerial': _serialProp,
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
        'deviceSerial': _serialProp,
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
        'deviceSerial': _serialProp,
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
  const McpToolDefinition(
    name: 'android_scroll',
    description: 'Performs a directional scroll or inertial fling gesture (up, down, left, right) on scrollable views (RecyclerView, ScrollView, LazyColumn).',
    inputSchema: {
      'type': 'object',
      'properties': {
        'direction': {
          'type': 'string',
          'enum': ['up', 'down', 'left', 'right'],
          'description': 'Scroll direction (down reveals lower content, up reveals higher content). Default: down.',
        },
        'distance': {
          'type': 'number',
          'description':
              'Fractional screen distance to scroll (0.1..1.0, default 0.6).',
        },
        'speed': {
          'type': 'string',
          'enum': ['fast', 'normal', 'slow'],
          'description': 'Scroll speed/inertia: fast (high-inertia fling), normal (smooth scroll), slow (drag). Default: normal.',
        },
        'startX': _coordProp,
        'startY': _coordProp,
        'endX': _coordProp,
        'endY': _coordProp,
        'startXRatio': _coordRatioProp,
        'startYRatio': _coordRatioProp,
        'endXRatio': _coordRatioProp,
        'endYRatio': _coordRatioProp,
        'startXPixel': _coordPixelProp,
        'startYPixel': _coordPixelProp,
        'endXPixel': _coordPixelProp,
        'endYPixel': _coordPixelProp,
        'durationMs': {
          'type': 'integer',
          'description': 'Optional explicit duration in milliseconds.',
        },
        'deviceSerial': _serialProp,
      },
    },
  ),
];
