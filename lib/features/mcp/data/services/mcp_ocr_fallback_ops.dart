import 'package:desk_droid/features/mcp/data/services/mcp_adb_client.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_tesseract_ocr_engine.dart';
import 'package:desk_droid/features/mcp/domain/entities/mcp_ocr_element.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_ocr_engine.dart';

/// Implements Stage 3 OCR fallback element discovery for zero-accessibility screens.
class McpOcrFallbackOps {
  const McpOcrFallbackOps();

  static McpOcrEngine _defaultEngine = McpTesseractOcrEngine();

  /// Overrides the global default OCR engine (primarily for unit testing).
  static void setDefaultEngineForTesting(McpOcrEngine? engine) {
    _defaultEngine = engine ?? McpTesseractOcrEngine();
  }

  /// Attempts to discover an on-screen element via OCR when accessibility trees yield no match.
  static Future<Map<String, dynamic>?> findElementViaOcr(
    McpAdbClient client,
    String serial, {
    required String text,
    McpOcrEngine? ocrEngine,
  }) async {
    final cleanQuery = text.trim();
    if (cleanQuery.isEmpty) return null;

    final engine = ocrEngine ?? _defaultEngine;
    if (!await engine.isAvailable()) return null;

    final imageBytes = await client.captureScreenshotBytes(serial);
    if (imageBytes == null || imageBytes.isEmpty) return null;

    final elements = await engine.recognize(imageBytes);
    if (elements.isEmpty) return null;

    final match = _findBestMatch(elements, cleanQuery);
    if (match == null) return null;

    final size = await client.getDisplaySize(serial);
    return match.toMap(screenWidth: size.x, screenHeight: size.y);
  }

  static McpOcrElement? _findBestMatch(
    List<McpOcrElement> elements,
    String query,
  ) {
    final lowerQuery = query.toLowerCase();

    // 1. Exact match (case-insensitive)
    for (final el in elements) {
      if (el.text.trim().toLowerCase() == lowerQuery) {
        return el;
      }
    }

    // 2. Contains match (element text contains query)
    for (final el in elements) {
      if (el.text.toLowerCase().contains(lowerQuery)) {
        return el;
      }
    }

    // 3. Query contains element text (if query is multi-word and word is prominent)
    for (final el in elements) {
      final elText = el.text.trim().toLowerCase();
      if (elText.length >= 3 && lowerQuery.contains(elText)) {
        return el;
      }
    }

    return null;
  }
}
