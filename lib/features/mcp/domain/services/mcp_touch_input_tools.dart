import 'package:desk_droid/features/mcp/domain/entities/mcp_tool_definition.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_schema_fragments.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_tool_annotations.dart';

/// Catalog of touch gestures, text entry, and basic hardware input tools for MCP.
final List<McpToolDefinition> mcpTouchInputTools = [
  const McpToolDefinition(
    name: 'android_tap',
    annotations: inputToolAnnotations,
    description: 'Taps one point on the screen. Prefer android_click_element_by_id or android_click_element when the element is in the semantic tree. Give the point as x/y, xRatio/yRatio, or xPixel/yPixel (units may be mixed per axis); one form is required.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': mcpDeviceSerialProp,
        'x': mcpCoordProp,
        'y': mcpCoordProp,
        'xRatio': mcpCoordRatioProp,
        'yRatio': mcpCoordRatioProp,
        'xPixel': mcpCoordPixelProp,
        'yPixel': mcpCoordPixelProp,
        'verifyChange': {
          'type': 'boolean',
          'description': 'Optional. If true, inspects UI hierarchy before and after tap (~300ms window) to verify whether the gesture caused a detectable UI state change.',
        },
        'verifyDelayMs': {
          'type': 'integer',
          'description': 'Optional wait duration in milliseconds before capturing post-tap hierarchy (default 300ms for animation settlement).',
        },
      },
    },
  ),
  const McpToolDefinition(
    name: 'android_double_tap',
    annotations: inputToolAnnotations,
    description: 'Double-taps one point (two taps intervalMs apart, default 120 ms), e.g. to zoom or to seek a video. Give the point as x/y, xRatio/yRatio, or xPixel/yPixel (units may be mixed per axis); one form is required.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': mcpDeviceSerialProp,
        'x': mcpCoordProp,
        'y': mcpCoordProp,
        'xRatio': mcpCoordRatioProp,
        'yRatio': mcpCoordRatioProp,
        'xPixel': mcpCoordPixelProp,
        'yPixel': mcpCoordPixelProp,
        'intervalMs': {
          'type': 'integer',
          'description': 'Delay between taps in milliseconds (default 120ms).',
        },
      },
    },
  ),
  const McpToolDefinition(
    name: 'android_swipe',
    annotations: inputToolAnnotations,
    description: 'Quick flick from start to end (default 300 ms) that keeps scrolling with inertia. Use android_drag for sliders and precise moves, android_scroll for plain list scrolling. Give start and end as startX/startY and endX/endY, or their *Ratio / *Pixel forms.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': mcpDeviceSerialProp,
        'startX': mcpCoordProp,
        'startY': mcpCoordProp,
        'endX': mcpCoordProp,
        'endY': mcpCoordProp,
        'startXRatio': mcpCoordRatioProp,
        'startYRatio': mcpCoordRatioProp,
        'endXRatio': mcpCoordRatioProp,
        'endYRatio': mcpCoordRatioProp,
        'startXPixel': mcpCoordPixelProp,
        'startYPixel': mcpCoordPixelProp,
        'endXPixel': mcpCoordPixelProp,
        'endYPixel': mcpCoordPixelProp,
        'durationMs': {
          'type': 'integer',
          'description': 'Duration of the swipe in ms (default 300ms).',
        },
      },
    },
  ),
  const McpToolDefinition(
    name: 'android_drag',
    annotations: inputToolAnnotations,
    description: 'Slow, controlled move from start to end (default 1000 ms) for sliders, seek bars, and reordering. Give start and end as startX/startY and endX/endY, or their *Ratio / *Pixel forms.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': mcpDeviceSerialProp,
        'startX': mcpCoordProp,
        'startY': mcpCoordProp,
        'endX': mcpCoordProp,
        'endY': mcpCoordProp,
        'startXRatio': mcpCoordRatioProp,
        'startYRatio': mcpCoordRatioProp,
        'endXRatio': mcpCoordRatioProp,
        'endYRatio': mcpCoordRatioProp,
        'startXPixel': mcpCoordPixelProp,
        'startYPixel': mcpCoordPixelProp,
        'endXPixel': mcpCoordPixelProp,
        'endYPixel': mcpCoordPixelProp,
        'durationMs': {
          'type': 'integer',
          'description': 'Drag duration in milliseconds (default 1000ms).',
        },
      },
    },
  ),
  const McpToolDefinition(
    name: 'android_type_text',
    annotations: inputToolAnnotations,
    description: 'Types ASCII text into the focused field as key events. Android cannot type other characters this way (accents, CJK, emoji fail with an error); use android_set_text for them. The device clipboard is not touched.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': mcpDeviceSerialProp,
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
    annotations: inputToolAnnotations,
    description: 'Sets exact text in the focused field, or in element elementId from the semantic tree. Pastes through the device clipboard (replacing it), so IMEs such as Telex cannot alter it. Where the clipboard cannot be set over adb (no `cmd clipboard`, as on the Android 10 and 13 devices tested), ASCII text is typed instead and other text fails with an error; the result says which happened.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': mcpDeviceSerialProp,
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
    annotations: inputToolAnnotations,
    description: 'Clears all existing text in the currently focused input field or target element by ID in a single shot.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': mcpDeviceSerialProp,
        'elementId': {
          'type': 'integer',
          'description': 'Optional target element ID from semantic tree to tap before clearing.',
        },
      },
    },
  ),
  const McpToolDefinition(
    name: 'android_press_key',
    annotations: inputToolAnnotations,
    description: 'Presses an Android hardware or system navigation key (BACK, HOME, APP_SWITCH, ENTER, TAB, POWER, VOLUME_UP, VOLUME_DOWN). For media, camera, wake, or sleep controls prefer android_press_button.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': mcpDeviceSerialProp,
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
    annotations: inputToolAnnotations,
    description: 'Scrolls content in a direction (down reveals lower content) through the screen center, or along an explicit start/end path. speed: fast flings, normal scrolls, slow drags.',
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
        'startX': mcpCoordProp,
        'startY': mcpCoordProp,
        'endX': mcpCoordProp,
        'endY': mcpCoordProp,
        'startXRatio': mcpCoordRatioProp,
        'startYRatio': mcpCoordRatioProp,
        'endXRatio': mcpCoordRatioProp,
        'endYRatio': mcpCoordRatioProp,
        'startXPixel': mcpCoordPixelProp,
        'startYPixel': mcpCoordPixelProp,
        'endXPixel': mcpCoordPixelProp,
        'endYPixel': mcpCoordPixelProp,
        'durationMs': {
          'type': 'integer',
          'description': 'Optional explicit duration in milliseconds.',
        },
        'deviceSerial': mcpDeviceSerialProp,
      },
    },
  ),
];
