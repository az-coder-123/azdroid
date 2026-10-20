part of 'mcp_adb_client.dart';

/// Implements Smart Waiting and Host Condition Polling for ADB MCP.
class McpAdbAutomationOps {
  const McpAdbAutomationOps._();

  static Future<Map<String, dynamic>?> waitForElement(
    McpAdbClient client,
    String serial, {
    String? text,
    String? resourceId,
    String? contentDesc,
    int timeoutMs = 10000,
    int pollIntervalMs = 500,
  }) async {
    final start = DateTime.now();
    final end = start.add(Duration(milliseconds: timeoutMs));
    while (DateTime.now().isBefore(end)) {
      final found = await McpAdbUiOps.findElement(
        client,
        serial,
        text: text,
        resourceId: resourceId,
        contentDesc: contentDesc,
      );
      if (found != null) {
        return {
          ...found,
          'elapsedMs': DateTime.now().difference(start).inMilliseconds,
        };
      }
      await Future<void>.delayed(Duration(milliseconds: pollIntervalMs));
    }
    return null;
  }

  static Future<Map<String, dynamic>> waitForCondition(
    McpAdbClient client,
    String serial, {
    required String condition,
    String? target,
    String? text,
    String? resourceId,
    String? contentDesc,
    int timeoutMs = 10000,
    int pollIntervalMs = 300,
  }) async {
    final start = DateTime.now();
    final end = start.add(Duration(milliseconds: timeoutMs));
    final normalized = condition.toLowerCase().trim();

    while (DateTime.now().isBefore(end)) {
      switch (normalized) {
        case 'element_present':
          final found = await McpAdbUiOps.findElement(
            client,
            serial,
            text: text,
            resourceId: resourceId,
            contentDesc: contentDesc,
          );
          if (found != null) {
            return {
              'conditionMet': true,
              'condition': 'element_present',
              'elapsedMs': DateTime.now().difference(start).inMilliseconds,
              'element': found,
            };
          }

        case 'element_gone':
          final found = await McpAdbUiOps.findElement(
            client,
            serial,
            text: text,
            resourceId: resourceId,
            contentDesc: contentDesc,
          );
          if (found == null) {
            return {
              'conditionMet': true,
              'condition': 'element_gone',
              'elapsedMs': DateTime.now().difference(start).inMilliseconds,
            };
          }

        case 'activity_resumed':
          final app = await client.getCurrentApp(serial);
          if (app != null) {
            final query = (target ?? text ?? '').toLowerCase();
            final act = (app['activity'] ?? '').toLowerCase();
            final pkg = (app['package'] ?? '').toLowerCase();
            if (act.contains(query) || pkg.contains(query)) {
              return {
                'conditionMet': true,
                'condition': 'activity_resumed',
                'elapsedMs': DateTime.now().difference(start).inMilliseconds,
                'package': app['package'],
                'activity': app['activity'],
              };
            }
          }

        case 'logcat_match':
          final query = target ?? text ?? '';
          if (query.isNotEmpty) {
            final logs = await client.getLogcat(serial, limit: 100);
            final regex = RegExp(query, caseSensitive: false);
            final match = regex.firstMatch(logs);
            if (match != null) {
              return {
                'conditionMet': true,
                'condition': 'logcat_match',
                'elapsedMs': DateTime.now().difference(start).inMilliseconds,
                'matched': match.group(0),
              };
            }
          }

        default:
          return {
            'conditionMet': false,
            'condition': normalized,
            'error': 'Unsupported condition: $condition',
          };
      }
      await Future<void>.delayed(Duration(milliseconds: pollIntervalMs));
    }

    return {
      'conditionMet': false,
      'condition': normalized,
      'elapsedMs': DateTime.now().difference(start).inMilliseconds,
      'error': 'Timed out after ${timeoutMs}ms waiting for $normalized',
    };
  }
}
