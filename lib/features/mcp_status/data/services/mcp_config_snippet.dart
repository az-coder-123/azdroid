import 'dart:convert';

import 'package:desk_droid/core/constants/mcp_status_constants.dart';

/// Builds the `mcpServers` JSON an AI client needs to launch [executable].
///
/// The same shape works for Claude Desktop, Cursor, and Antigravity
/// (docs/mcp-setup-guide.md). `jsonEncode` escapes Windows backslashes.
String buildMcpConfigSnippet(String executable) =>
    const JsonEncoder.withIndent('  ').convert({
      'mcpServers': {
        McpStatusConstants.configServerKey: {'command': executable},
      },
    });
