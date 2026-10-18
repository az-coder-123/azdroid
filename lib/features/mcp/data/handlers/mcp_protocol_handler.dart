import 'dart:convert';

import 'package:desk_droid/core/constants/app_constants.dart';
import 'package:desk_droid/features/mcp/data/handlers/mcp_tool_executor.dart';
import 'package:desk_droid/features/mcp/domain/entities/mcp_json_rpc.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_tool_registry.dart';

/// Handles parsing, routing, and response formatting for the MCP JSON-RPC 2.0 protocol.
class McpProtocolHandler {
  McpProtocolHandler({McpToolRegistry? registry, McpToolExecutor? executor})
    : _registry = registry ?? const McpToolRegistry(),
      _executor = executor ?? McpToolExecutor();

  final McpToolRegistry _registry;
  final McpToolExecutor _executor;

  static const String protocolVersion = '2024-11-05';
  static const String serverName = 'deskdroid-mcp';
  static const String serverVersion = AppConstants.appVersion;

  /// Processes an incoming raw JSON-RPC string message. Returns null if notification.
  Future<String?> handleMessage(String rawJson) async {
    final trimmed = rawJson.trim();
    if (trimmed.isEmpty) return null;

    Map<String, dynamic> jsonMap;
    try {
      final parsed = jsonDecode(trimmed);
      if (parsed is! Map<String, dynamic>) {
        return jsonEncode(
          const McpResponse(
            error: McpError(
              code: McpError.invalidRequest,
              message: 'Invalid JSON-RPC request object',
            ),
          ).toJson(),
        );
      }
      jsonMap = parsed;
    } catch (_) {
      return jsonEncode(
        const McpResponse(
          error: McpError(
            code: McpError.parseError,
            message: 'Failed to parse JSON string',
          ),
        ).toJson(),
      );
    }

    final request = McpRequest.fromJson(jsonMap);
    final response = await handleRequest(request);
    return response != null ? jsonEncode(response.toJson()) : null;
  }

  /// Evaluates an McpRequest and produces an McpResponse (or null for notifications).
  Future<McpResponse?> handleRequest(McpRequest request) async {
    // Notifications have no id and expect no response
    if (request.isNotification) {
      return null;
    }

    switch (request.method) {
      case 'initialize':
        return McpResponse(
          id: request.id,
          result: {
            'protocolVersion': protocolVersion,
            'capabilities': {
              'tools': {'listChanged': false},
            },
            'serverInfo': {'name': serverName, 'version': serverVersion},
          },
        );

      case 'ping':
        return McpResponse(id: request.id, result: <String, dynamic>{});

      case 'tools/list':
        final tools = _registry.getTools();
        return McpResponse(
          id: request.id,
          result: {'tools': tools.map((t) => t.toJson()).toList()},
        );

      case 'tools/call':
        final params = request.params ?? {};
        final name = params['name'] as String?;
        if (name == null || name.isEmpty) {
          return McpResponse(
            id: request.id,
            error: const McpError(
              code: McpError.invalidParams,
              message: 'Missing required "name" parameter in tools/call.',
            ),
          );
        }
        final arguments = params['arguments'] is Map<String, dynamic>
            ? params['arguments'] as Map<String, dynamic>
            : <String, dynamic>{};

        final toolResult = await _executor.execute(name, arguments);
        return McpResponse(id: request.id, result: toolResult.toJson());

      default:
        return McpResponse(
          id: request.id,
          error: McpError(
            code: McpError.methodNotFound,
            message: 'Method not found: ${request.method}',
          ),
        );
    }
  }
}
