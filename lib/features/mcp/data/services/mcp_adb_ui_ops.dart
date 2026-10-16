part of 'mcp_adb_client.dart';

/// Static operations for UI hierarchy inspection, element querying, and semantic clicking.
class McpAdbUiOps {
  const McpAdbUiOps._();

  /// Captures the active window UI hierarchy XML using uiautomator dump.
  static Future<String> dumpHierarchy(
    McpAdbClient client,
    String serial,
  ) async {
    const tmpXml = '/data/local/tmp/window_dump.xml';
    final dumpRes = await client.run([
      '-s',
      serial,
      'shell',
      'uiautomator',
      'dump',
      tmpXml,
    ]);
    if (dumpRes.exitCode != 0) {
      return 'Error: Failed to dump UI hierarchy: ${dumpRes.stderr}';
    }

    final catRes = await client.run(['-s', serial, 'shell', 'cat', tmpXml]);
    return catRes.stdout.toString().trim();
  }

  /// Parses UI hierarchy XML and searches for the first element matching text, ID, or description.
  static Future<Map<String, dynamic>?> findElement(
    McpAdbClient client,
    String serial, {
    String? text,
    String? resourceId,
    String? contentDesc,
  }) async {
    final xml = await dumpHierarchy(client, serial);
    if (xml.startsWith('Error:')) return null;

    final nodeRegex = RegExp(
      r'text="([^"]*)"[^>]*resource-id="([^"]*)"[^>]*class="([^"]*)"[^>]*package="([^"]*)"[^>]*content-desc="([^"]*)"[^>]*clickable="([^"]*)"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"',
    );

    final size = await client.getDisplaySize(serial);

    for (final match in nodeRegex.allMatches(xml)) {
      final nodeText = match.group(1) ?? '';
      final nodeId = match.group(2) ?? '';
      final nodeClass = match.group(3) ?? '';
      final nodePkg = match.group(4) ?? '';
      final nodeDesc = match.group(5) ?? '';
      final clickable = match.group(6) == 'true';
      final left = int.parse(match.group(7)!);
      final top = int.parse(match.group(8)!);
      final right = int.parse(match.group(9)!);
      final bottom = int.parse(match.group(10)!);

      bool matches = false;
      if (text != null &&
          text.isNotEmpty &&
          nodeText.toLowerCase().contains(text.toLowerCase())) {
        matches = true;
      } else if (resourceId != null &&
          resourceId.isNotEmpty &&
          nodeId.toLowerCase().contains(resourceId.toLowerCase())) {
        matches = true;
      } else if (contentDesc != null &&
          contentDesc.isNotEmpty &&
          nodeDesc.toLowerCase().contains(contentDesc.toLowerCase())) {
        matches = true;
      }

      if (matches) {
        final centerX = (left + right) ~/ 2;
        final centerY = (top + bottom) ~/ 2;
        final normX = size.x > 0
            ? double.parse((centerX / size.x).toStringAsFixed(4))
            : 0.0;
        final normY = size.y > 0
            ? double.parse((centerY / size.y).toStringAsFixed(4))
            : 0.0;

        return {
          'text': nodeText,
          'resourceId': nodeId,
          'class': nodeClass,
          'package': nodePkg,
          'contentDesc': nodeDesc,
          'clickable': clickable,
          'bounds': '[$left,$top][$right,$bottom]',
          'centerPixels': {'x': centerX, 'y': centerY},
          'normalized': {'x': normX, 'y': normY},
        };
      }
    }
    return null;
  }

  /// Locates an element matching criteria and taps its center coordinates.
  static Future<bool> clickElement(
    McpAdbClient client,
    String serial, {
    String? text,
    String? resourceId,
    String? contentDesc,
  }) async {
    final element = await findElement(
      client,
      serial,
      text: text,
      resourceId: resourceId,
      contentDesc: contentDesc,
    );
    if (element == null) return false;

    final center = element['centerPixels'] as Map<String, dynamic>;
    final x = (center['x'] as int).toDouble();
    final y = (center['y'] as int).toDouble();
    return await client.tap(serial, x, y);
  }
}
