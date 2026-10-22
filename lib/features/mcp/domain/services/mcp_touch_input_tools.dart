import 'package:desk_droid/features/mcp/domain/entities/mcp_tool_definition.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_schema_fragments.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_tool_annotations.dart';

/// Catalog of touch gestures, text entry, and basic hardware input tools for MCP.
final List<McpToolDefinition> mcpTouchInputTools = [
  const McpToolDefinition(
    name: 'android_tap',
    annotations: inputToolAnnotations,
    description: 'Taps one point: once (default), twice with taps: 2 (e.g. zoom or seek a video), or press and hold with holdMs (e.g. a context menu). Prefer android_click_element when the element is in the UI tree. Give the point as x/y, xRatio/yRatio, or xPixel/yPixel (units may be mixed per axis); one form is required.',
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
        'taps': {
          'type': 'integer',
          'enum': [1, 2],
          'description': '1 (default) or 2 for a double tap.',
        },
        'intervalMs': {
          'type': 'integer',
          'description': 'Double tap: gap between taps in ms (default 120).',
        },
        'holdMs': {
          'type': 'integer',
          'description': 'Press and hold this long in ms (long press).',
        },
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
    name: 'android_swipe',
    annotations: inputToolAnnotations,
    description: 'Moves one finger. With start and end: a quick flick that keeps scrolling with inertia (default 300 ms), or style "drag" for a slow, precise move (default 1000 ms) for sliders and reordering; give them as startX/startY and endX/endY or their *Ratio / *Pixel forms. With direction instead: scrolls content through the screen center (down reveals lower content) by distance at speed.',
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
        'style': {
          'type': 'string',
          'enum': ['fling', 'drag'],
          'description': 'fling (default) or drag (slow, precise).',
        },
        'direction': {
          'type': 'string',
          'enum': ['up', 'down', 'left', 'right'],
          'description': 'Scroll content this way instead of a start/end path.',
        },
        'distance': {
          'type': 'number',
          'description': 'Scroll: screen fraction 0.1-1.0 (default 0.6).',
        },
        'speed': {
          'type': 'string',
          'enum': ['fast', 'normal', 'slow'],
          'description': 'Scroll: fast flings, normal, slow drags.',
        },
        'durationMs': {
          'type': 'integer',
          'description': 'Gesture duration in ms (overrides the defaults).',
        },
      },
    },
  ),
  const McpToolDefinition(
    name: 'android_press_key',
    annotations: inputToolAnnotations,
    description: 'Presses a key or button: navigation (BACK, HOME, APP_SWITCH, ENTER, TAB), hardware (POWER, VOLUME_UP, VOLUME_DOWN, MUTE, CAMERA), screen power (WAKEUP, SLEEP), media (MEDIA_PLAY_PAUSE, MEDIA_NEXT, MEDIA_PREV), or status bar panels (NOTIFICATIONS, QUICK_SETTINGS, CLOSE_PANELS).',
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
            'MUTE',
            'CAMERA',
            'WAKEUP',
            'SLEEP',
            'MEDIA_PLAY_PAUSE',
            'MEDIA_NEXT',
            'MEDIA_PREV',
            'NOTIFICATIONS',
            'QUICK_SETTINGS',
            'CLOSE_PANELS',
          ],
          'description': 'Key name to press.',
        },
      },
      'required': ['key'],
    },
  ),
];
