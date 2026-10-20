import 'package:desk_droid/features/mcp/domain/entities/mcp_tool_definition.dart';

/// Catalog of Smart Waiting, Condition Monitoring, and Macro Batching tools for DeskDroid MCP.
class McpAutomationTools {
  const McpAutomationTools._();

  static List<McpToolDefinition> get tools => const [
    McpToolDefinition(
      name: 'android_wait_for_element',
      description:
          'Polls the UI hierarchy until an element matching text, resourceId, or contentDesc appears, avoiding unnecessary LLM round-trips.',
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
      name: 'android_wait_for_condition',
      description:
          'Polls host-side conditions (element_present, element_gone, activity_resumed, logcat_match) with configurable intervals and timeouts, saving multi-turn LLM polling overhead.',
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
            'description': 'Target content description for element_present/gone.',
          },
          'timeoutMs': {
            'type': 'integer',
            'description': 'Maximum wait duration in ms (default 10000).',
          },
          'pollIntervalMs': {
            'type': 'integer',
            'description': 'Host polling interval in ms (default 300).',
          },
          'deviceSerial': {
            'type': 'string',
            'description': 'Target device serial or IP:port.',
          },
        },
        'required': ['condition'],
      },
    ),
    McpToolDefinition(
      name: 'android_batch_actions',
      description:
          'Executes a sequential compound macro of actions (tap, type, key, swipe, sleep) locally in one shot.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'actions': {
            'type': 'array',
            'description':
                'List of action maps: {"action": "tap"|"type"|"key"|"swipe"|"sleep", ...}',
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
  ];
}
