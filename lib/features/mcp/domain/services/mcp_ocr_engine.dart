import 'package:desk_droid/features/mcp/domain/entities/mcp_ocr_element.dart';

/// Contract for text recognition engines supplying Stage 3 element discovery.
abstract class McpOcrEngine {
  /// Checks whether the underlying OCR binary or model is operational.
  Future<bool> isAvailable();

  /// Performs optical character recognition on [imageBytes] and returns detected elements.
  Future<List<McpOcrElement>> recognize(List<int> imageBytes);
}
