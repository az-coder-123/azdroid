import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:desk_droid/features/mcp/data/handlers/mcp_protocol_handler.dart';

/// Transport adapter executing the MCP JSON-RPC protocol over standard I/O (stdin/stdout).
class McpStdioTransport {
  McpStdioTransport({
    McpProtocolHandler? handler,
    this.inputStream,
    this.outputSink,
  }) : _handler = handler ?? McpProtocolHandler();

  final McpProtocolHandler _handler;
  final Stream<String>? inputStream;
  final void Function(String)? outputSink;

  /// Starts listening to the input stream and replying via stdout.
  Future<void> run() async {
    final stream =
        inputStream ??
        stdin.transform(utf8.decoder).transform(const LineSplitter());

    final sink = outputSink ?? (String line) => stdout.writeln(line);

    await for (final line in stream) {
      final responseJson = await _handler.handleMessage(line);
      if (responseJson != null) {
        sink(responseJson);
      }
    }
    // stdin closed: the AI client disconnected.
    await _handler.close();
  }
}
