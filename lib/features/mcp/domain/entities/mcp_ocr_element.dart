import 'package:equatable/equatable.dart';

/// Represents an on-screen text element discovered via OCR.
class McpOcrElement extends Equatable {
  const McpOcrElement({
    required this.text,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    this.confidence = 1.0,
  });

  final String text;
  final int left;
  final int top;
  final int width;
  final int height;
  final double confidence;

  int get right => left + width;
  int get bottom => top + height;
  int get centerX => left + (width ~/ 2);
  int get centerY => top + (height ~/ 2);
  String get bounds => '[$left,$top][$right,$bottom]';

  /// Serializes into the standard MCP element JSON format.
  Map<String, dynamic> toMap({int screenWidth = 0, int screenHeight = 0}) {
    final normX = screenWidth > 0 ? centerX / screenWidth : 0.0;
    final normY = screenHeight > 0 ? centerY / screenHeight : 0.0;

    return {
      'id': -1,
      'text': text,
      'resourceId': '',
      'class': 'OcrTextElement',
      'package': '',
      'contentDesc': '',
      'clickable': true,
      'scrollable': false,
      'bounds': bounds,
      'centerPixels': {'x': centerX, 'y': centerY},
      'normalized': {
        'x': double.parse(normX.toStringAsFixed(4)),
        'y': double.parse(normY.toStringAsFixed(4)),
      },
      'confidence': double.parse(confidence.toStringAsFixed(2)),
      'source': 'ocr_stage_3',
    };
  }

  @override
  List<Object?> get props => [text, left, top, width, height, confidence];
}
