import 'package:desk_droid/features/mcp/data/services/mcp_adb_client.dart';
import 'package:desk_droid/features/mcp/data/utils/mcp_argument_helper.dart';
import 'package:desk_droid/features/mcp/domain/entities/mcp_tool_definition.dart';

/// Handler for smart element waiting, condition monitoring, and macro batching tools.
class McpAutomationToolExecutor {
  const McpAutomationToolExecutor(this._adb);

  final McpAdbClient _adb;

  bool canHandle(String toolName) {
    return const {
      'android_wait_for_element',
      'android_wait_for_condition',
      'android_batch_actions',
    }.contains(toolName);
  }

  Future<McpToolResult> execute(
    String toolName,
    String serial,
    Map<String, dynamic> arguments,
  ) async {
    try {
      return await _executeInternal(toolName, serial, arguments);
    } on McpArgumentException catch (e) {
      return McpToolResult.error(e.message);
    }
  }

  Future<McpToolResult> _executeInternal(
    String toolName,
    String serial,
    Map<String, dynamic> arguments,
  ) async {
    switch (toolName) {
      case 'android_wait_for_element':
        final text = arguments.getString('text');
        final resId = arguments.getString(
          'resourceId',
          aliases: ['resId', 'id'],
        );
        final desc = arguments.getString(
          'contentDesc',
          aliases: ['desc', 'contentDescription'],
        );
        final timeout = arguments.getInt(
          'timeoutMs',
          aliases: ['timeout'],
          defaultValue: 10000,
        );
        final poll = arguments.getInt(
          'pollIntervalMs',
          aliases: ['pollInterval', 'interval'],
          defaultValue: 500,
        );
        final res = await _adb.waitForElement(
          serial,
          text: text,
          resourceId: resId,
          contentDesc: desc,
          timeoutMs: timeout,
          pollIntervalMs: poll,
        );
        if (res == null) {
          return McpToolResult.error('Element timed out after ${timeout}ms.');
        }
        return McpToolResult.text(
          'Element appeared (${res['elapsedMs']}ms):\n$res',
        );

      case 'android_wait_for_condition':
        final condition = arguments.getRequiredString(
          'condition',
          aliases: ['type', 'cond'],
        );
        final target = arguments.getString(
          'target',
          aliases: ['pattern', 'activity', 'name'],
        );
        final text = arguments.getString('text');
        final resId = arguments.getString(
          'resourceId',
          aliases: ['resId', 'id'],
        );
        final desc = arguments.getString(
          'contentDesc',
          aliases: ['desc', 'contentDescription'],
        );
        final timeout = arguments.getInt(
          'timeoutMs',
          aliases: ['timeout'],
          defaultValue: 10000,
        );
        final poll = arguments.getInt(
          'pollIntervalMs',
          aliases: ['pollInterval', 'interval'],
          defaultValue: 300,
        );
        final res = await _adb.waitForCondition(
          serial,
          condition: condition,
          target: target,
          text: text,
          resourceId: resId,
          contentDesc: desc,
          timeoutMs: timeout,
          pollIntervalMs: poll,
        );
        final met = res['conditionMet'] == true;
        return met
            ? McpToolResult.text(
                'Condition "$condition" met (${res['elapsedMs']}ms):\n$res',
              )
            : McpToolResult.error(
                res['error']?.toString() ??
                    'Condition "$condition" timed out after ${timeout}ms.',
              );

      case 'android_batch_actions':
        final rawActions = arguments['actions'];
        final list = <Map<String, dynamic>>[];
        if (rawActions is List) {
          for (final item in rawActions) {
            if (item is Map) {
              list.add(Map<String, dynamic>.from(item));
            }
          }
        }
        final res = await _adb.batchActions(serial, list);
        return McpToolResult.text(
          'Executed ${res.length} batch actions on $serial:\n$res',
        );

      default:
        return McpToolResult.error('Unknown tool: $toolName');
    }
  }
}
