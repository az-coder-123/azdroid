import 'package:desk_droid/features/mcp/domain/entities/mcp_tool_definition.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_schema_fragments.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_tool_annotations.dart';

/// Catalog of Smart Waiting, Condition Monitoring, and Macro Batching tools for Azdroid MCP.
class McpAutomationTools {
  const McpAutomationTools._();

  static List<McpToolDefinition> get tools => const [
    McpToolDefinition(
      name: 'android_wait_for_element',
      annotations: readOnlyToolAnnotations,
      description: 'Waits on the computer until an element matching text, resourceId, or contentDesc appears (give at least one), instead of polling with repeated calls. Use android_wait_for_condition for element_gone, activity_resumed, or logcat_match.',
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
          'deviceSerial': mcpDeviceSerialProp,
        },
      },
    ),
    McpToolDefinition(
      name: 'android_wait_for_condition',
      annotations: readOnlyToolAnnotations,
      description: 'Polls host-side conditions (element_present, element_gone, activity_resumed, logcat_match) with configurable intervals and timeouts, saving multi-turn LLM polling overhead.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'condition': {
            'type': 'string',
            'enum': [
              'element_present',
              'element_gone',
              'activity_resumed',
              'logcat_match',
            ],
            'description': 'Target state condition to wait for.',
          },
          'target': {
            'type': 'string',
            'description':
                'Target substring/regex for activity_resumed or logcat_match.',
          },
          'text': {
            'type': 'string',
            'description': 'Target text to match for element_present/gone.',
          },
          'resourceId': {
            'type': 'string',
            'description': 'Target resource ID for element_present/gone.',
          },
          'contentDesc': {
            'type': 'string',
            'description':
                'Target content description for element_present/gone.',
          },
          'timeoutMs': {
            'type': 'integer',
            'description': 'Maximum wait duration in ms (default 10000).',
          },
          'pollIntervalMs': {
            'type': 'integer',
            'description': 'Host polling interval in ms (default 300).',
          },
          'deviceSerial': mcpDeviceSerialProp,
        },
        'required': ['condition'],
      },
    ),
    McpToolDefinition(
      name: 'android_batch_actions',
      annotations: inputToolAnnotations,
      description: 'Executes a sequential compound macro of actions (tap, double_tap, type, key, swipe, scroll, fling, pinch, rotate, sleep) locally in one shot.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'actions': {
            'type': 'array',
            'description':
                'List of action maps. Each requires an "action" '
                'field plus per-type fields (defaults in parentheses): '
                'tap/double_tap: x, y (ratio when both <= 1.0, else pixels; '
                'intervalMs 120 for double_tap) — {"action":"tap","x":0.5,"y":0.5}; '
                'type: text — {"action":"type","text":"hello"}; '
                'key: keyCode (numeric Android keycode) — {"action":"key","keyCode":66}; '
                'swipe: startX, startY, endX, endY, durationMs (300); '
                'scroll/fling: direction (down), distance (0.6), speed '
                'fast|normal|slow (normal), durationMs; '
                'pinch: scale (1.5), centerX, centerY (0.5), durationMs (400); '
                'rotate: angleDegrees (90), centerX, centerY (0.5), radius '
                '(200), durationMs (400); '
                'sleep: durationMs (500) — {"action":"sleep","durationMs":800}.',
            'items': {'type': 'object'},
          },
          'deviceSerial': mcpDeviceSerialProp,
        },
        'required': ['actions'],
      },
    ),
  ];
}
