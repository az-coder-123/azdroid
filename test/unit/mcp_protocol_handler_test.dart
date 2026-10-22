import 'dart:convert';

import 'package:desk_droid/features/mcp/data/handlers/mcp_protocol_handler.dart';
import 'package:desk_droid/features/mcp/domain/entities/mcp_json_rpc.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_protocol_version.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('McpProtocolHandler JSON-RPC Tests', () {
    late McpProtocolHandler handler;

    setUp(() {
      handler = McpProtocolHandler();
    });

    test(
      'initialize returns protocol version and server capabilities',
      () async {
        final requestJson = jsonEncode({
          'jsonrpc': '2.0',
          'id': 1,
          'method': 'initialize',
          'params': {'protocolVersion': '2024-11-05', 'capabilities': {}},
        });

        final responseStr = await handler.handleMessage(requestJson);
        expect(responseStr, isNotNull);

        final responseMap = jsonDecode(responseStr!) as Map<String, dynamic>;
        expect(responseMap['jsonrpc'], '2.0');
        expect(responseMap['id'], 1);

        final result = responseMap['result'] as Map<String, dynamic>;
        expect(result['protocolVersion'], '2024-11-05');
        expect(
          (result['serverInfo'] as Map<String, dynamic>)['name'],
          'azdroid-mcp',
        );
        expect(
          (result['capabilities'] as Map<String, dynamic>)['tools'],
          isNotNull,
        );
      },
    );

    test('initialize answers the revision the client asked for', () async {
      Future<String> negotiated(Object? requested) async {
        final response = await handler.handleMessage(
          jsonEncode({
            'jsonrpc': '2.0',
            'id': 3,
            'method': 'initialize',
            'params': {'protocolVersion': ?requested, 'capabilities': {}},
          }),
        );
        final result =
            (jsonDecode(response!) as Map<String, dynamic>)['result']
                as Map<String, dynamic>;
        return result['protocolVersion'] as String;
      }

      // Annotations need 2025-03-26 or later; such clients must get it back.
      expect(await negotiated('2025-03-26'), '2025-03-26');
      expect(await negotiated('2025-06-18'), '2025-06-18');
      expect(await negotiated('2024-11-05'), '2024-11-05');
      // Unknown or missing: the newest supported revision.
      expect(
        await negotiated('2099-01-01'),
        mcpSupportedProtocolVersions.first,
      );
      expect(await negotiated(null), mcpSupportedProtocolVersions.first);
    });

    test('initialize returns agent workflow instructions', () async {
      final requestJson = jsonEncode({
        'jsonrpc': '2.0',
        'id': 7,
        'method': 'initialize',
        'params': {'protocolVersion': '2024-11-05', 'capabilities': {}},
      });

      final responseStr = await handler.handleMessage(requestJson);
      final responseMap = jsonDecode(responseStr!) as Map<String, dynamic>;
      final result = responseMap['result'] as Map<String, dynamic>;

      final instructions = result['instructions'];
      expect(instructions, isA<String>());
      expect((instructions as String).trim(), isNotEmpty);

      // Guidance must reference the core verified workflows.
      expect(instructions, contains('android_list_devices'));
      expect(instructions, contains('android_get_semantic_tree'));
      expect(instructions, contains('android_click_element_by_id'));
      expect(instructions, contains('android_wait_for_condition'));
    });

    test(
      'notifications/initialized returns null (no response for notification)',
      () async {
        final notificationJson = jsonEncode({
          'jsonrpc': '2.0',
          'method': 'notifications/initialized',
        });

        final responseStr = await handler.handleMessage(notificationJson);
        expect(responseStr, isNull);
      },
    );

    test('ping returns empty result map', () async {
      final requestJson = jsonEncode({
        'jsonrpc': '2.0',
        'id': 42,
        'method': 'ping',
      });

      final responseStr = await handler.handleMessage(requestJson);
      expect(responseStr, isNotNull);

      final responseMap = jsonDecode(responseStr!) as Map<String, dynamic>;
      expect(responseMap['id'], 42);
      expect(responseMap['result'], isA<Map<String, dynamic>>());
    });

    test('tools/list returns registered Android tools', () async {
      final requestJson = jsonEncode({
        'jsonrpc': '2.0',
        'id': 2,
        'method': 'tools/list',
      });

      final responseStr = await handler.handleMessage(requestJson);
      expect(responseStr, isNotNull);

      final responseMap = jsonDecode(responseStr!) as Map<String, dynamic>;
      final result = responseMap['result'] as Map<String, dynamic>;
      final tools = result['tools'] as List<dynamic>;

      expect(tools.length, greaterThanOrEqualTo(9));
      final toolNames = tools
          .map((t) => (t as Map<String, dynamic>)['name'] as String)
          .toList();
      expect(toolNames, contains('android_list_devices'));
      expect(toolNames, contains('android_take_screenshot'));
      expect(toolNames, contains('android_tap'));
      expect(toolNames, contains('android_swipe'));
      expect(toolNames, contains('android_type_text'));
      expect(toolNames, contains('android_press_key'));
      expect(toolNames, contains('android_dispatch_intent'));
      expect(toolNames, contains('android_get_logcat'));
      expect(toolNames, contains('android_install_apk'));
      expect(toolNames, contains('android_shell_command'));
    });

    test('tools/call returns error when tool name is missing', () async {
      final requestJson = jsonEncode({
        'jsonrpc': '2.0',
        'id': 3,
        'method': 'tools/call',
        'params': {},
      });

      final responseStr = await handler.handleMessage(requestJson);
      expect(responseStr, isNotNull);

      final responseMap = jsonDecode(responseStr!) as Map<String, dynamic>;
      expect(responseMap['id'], 3);
      expect(responseMap['error'], isNotNull);
      expect(
        (responseMap['error'] as Map<String, dynamic>)['code'],
        McpError.invalidParams,
      );
    });

    test('returns methodNotFound for unknown method', () async {
      final requestJson = jsonEncode({
        'jsonrpc': '2.0',
        'id': 99,
        'method': 'unknown/nonexistent_method',
      });

      final responseStr = await handler.handleMessage(requestJson);
      expect(responseStr, isNotNull);

      final responseMap = jsonDecode(responseStr!) as Map<String, dynamic>;
      expect(responseMap['id'], 99);
      expect(
        (responseMap['error'] as Map<String, dynamic>)['code'],
        McpError.methodNotFound,
      );
    });

    test('returns parseError on malformed JSON payload', () async {
      const malformedJson = '{"jsonrpc": "2.0", "id": 1, INVALID_JSON';

      final responseStr = await handler.handleMessage(malformedJson);
      expect(responseStr, isNotNull);

      final responseMap = jsonDecode(responseStr!) as Map<String, dynamic>;
      expect(
        (responseMap['error'] as Map<String, dynamic>)['code'],
        McpError.parseError,
      );
    });

    test('ignores empty or whitespace-only messages', () async {
      final responseStr = await handler.handleMessage('   \n  ');
      expect(responseStr, isNull);
    });
  });
}
