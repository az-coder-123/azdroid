part of 'mcp_adb_client.dart';

/// Static operations for UI hierarchy inspection, semantic tree parsing, and element querying.
class McpAdbUiOps {
  const McpAdbUiOps._();

  static const _parser = McpSemanticTreeParser();
  static final Map<String, List<McpSemanticElement>> _cachedElements = {};

  /// Captures the active window UI hierarchy XML using uiautomator dump.
  static Future<String> dumpHierarchy(
    McpAdbClient client,
    String serial, {
    bool compressed = true,
  }) async {
    const tmpXml = '/data/local/tmp/window_dump.xml';

    final dumpArgs = compressed
        ? ['-s', serial, 'shell', 'uiautomator', 'dump', '--compressed', tmpXml]
        : ['-s', serial, 'shell', 'uiautomator', 'dump', tmpXml];

    var dumpRes = await client.run(dumpArgs);

    // Fallback to standard dump if --compressed is not supported.
    if (dumpRes.exitCode != 0 && compressed) {
      dumpRes = await client.run([
        '-s',
        serial,
        'shell',
        'uiautomator',
        'dump',
        tmpXml,
      ]);
    }

    final catRes = await client.run(['-s', serial, 'shell', 'cat', tmpXml]);
    final content = catRes.stdout.toString().trim();

    // Verify valid XML payload regardless of vendor stderr notices.
    if (content.contains('<hierarchy') || content.contains('<?xml')) {
      return content;
    }

    return 'Error: Failed to dump UI hierarchy: ${dumpRes.stderr}';
  }

  /// Extracts a pruned, token-efficient semantic tree digest and caches elements.
  static Future<String> getSemanticTree(
    McpAdbClient client,
    String serial,
  ) async {
    final xml = await dumpHierarchy(client, serial, compressed: true);
    if (xml.startsWith('Error:')) return xml;

    final size = await client.getDisplaySize(serial);
    var elements = _parser.parse(
      xml,
      screenWidth: size.x,
      screenHeight: size.y,
    );

    // Declarative fallback: if compressed hierarchy produces zero clickable or text
    // elements (common in Jetpack Compose / Flutter on MIUI and Android 10+), retry with
    // uncompressed dump to capture un-pruned canvas nodes.
    if (elements.isEmpty ||
        elements.every((e) => !e.clickable && e.text.isEmpty)) {
      final uncompressedXml = await dumpHierarchy(
        client,
        serial,
        compressed: false,
      );
      if (!uncompressedXml.startsWith('Error:')) {
        final uncompressedElements = _parser.parse(
          uncompressedXml,
          screenWidth: size.x,
          screenHeight: size.y,
        );
        if (uncompressedElements.isNotEmpty) {
          elements = uncompressedElements;
        }
      }
    }

    _cachedElements[serial] = elements;

    return _parser.formatDigest(elements);
  }

  /// Taps an element by its 1-based sequential ID from the cached semantic tree.
  static Future<bool> clickElementById(
    McpAdbClient client,
    String serial,
    int id,
  ) async {
    var elements = _cachedElements[serial];
    if (elements == null || elements.isEmpty) {
      // Refresh tree if cache is empty
      await getSemanticTree(client, serial);
      elements = _cachedElements[serial];
    }

    final target = elements?.where((e) => e.id == id).firstOrNull;
    if (target == null) return false;

    return await client.tap(
      serial,
      target.centerX.toDouble(),
      target.centerY.toDouble(),
    );
  }

  /// Parses UI hierarchy XML and searches for the first element matching text, ID, or description.
  static Future<Map<String, dynamic>?> findElement(
    McpAdbClient client,
    String serial, {
    String? text,
    String? resourceId,
    String? contentDesc,
  }) async {
    final xml = await dumpHierarchy(client, serial, compressed: true);
    if (xml.startsWith('Error:')) return null;

    final size = await client.getDisplaySize(serial);
    final elements = _parser.parse(
      xml,
      screenWidth: size.x,
      screenHeight: size.y,
    );
    _cachedElements[serial] = elements;

    var match = _parser.findByQuery(
      elements,
      text: text,
      resourceId: resourceId,
      contentDesc: contentDesc,
    );

    // Declarative fallback: If query found no match in compressed hierarchy,
    // re-attempt search against uncompressed dump for Compose / Flutter elements.
    if (match == null) {
      final uncompressedXml = await dumpHierarchy(
        client,
        serial,
        compressed: false,
      );
      if (!uncompressedXml.startsWith('Error:')) {
        final uncompressedElements = _parser.parse(
          uncompressedXml,
          screenWidth: size.x,
          screenHeight: size.y,
        );
        if (uncompressedElements.isNotEmpty) {
          _cachedElements[serial] = uncompressedElements;
          match = _parser.findByQuery(
            uncompressedElements,
            text: text,
            resourceId: resourceId,
            contentDesc: contentDesc,
          );
        }
      }
    }

    // Stage 3 — OCR Fallback: If both compressed and uncompressed dumps failed,
    // and a text query was provided, perform an OCR pass on the screen capture.
    if (match == null && text != null && text.trim().isNotEmpty) {
      final ocrMatch = await McpOcrFallbackOps.findElementViaOcr(
        client,
        serial,
        text: text,
      );
      if (ocrMatch != null) return ocrMatch;
    }

    return match?.toMap();
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
