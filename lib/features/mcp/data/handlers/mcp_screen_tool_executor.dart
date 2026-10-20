import 'dart:convert';

import 'package:desk_droid/features/mcp/data/services/mcp_adb_client.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_image_processor.dart';
import 'package:desk_droid/features/mcp/domain/entities/mcp_tool_definition.dart';

/// Handler for screen capture, region-of-interest cropping, and compression.
class McpScreenToolExecutor {
  const McpScreenToolExecutor(this._adb);

  final McpAdbClient _adb;

  bool canHandle(String toolName) => toolName == 'android_take_screenshot';

  Future<McpToolResult> execute(
    String toolName,
    String serial,
    Map<String, dynamic> arguments,
  ) async {
    final bytes = await _adb.captureScreenshotBytes(serial);
    if (bytes == null || bytes.isEmpty) {
      return McpToolResult.error('Failed to capture screenshot from $serial.');
    }

    final processed = McpImageProcessor.processFromArguments(bytes, arguments);
    final isJpeg = McpImageProcessor.isJpeg(arguments['format']);
    final mimeType = isJpeg ? 'image/jpeg' : 'image/png';

    return McpToolResult.image(
      base64Data: base64Encode(processed),
      mimeType: mimeType,
      caption:
          'Screenshot from device $serial at ${DateTime.now().toIso8601String()}',
    );
  }
}
