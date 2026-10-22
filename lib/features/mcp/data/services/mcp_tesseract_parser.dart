import 'dart:math';

import 'package:desk_droid/core/extensions/line_split_extension.dart';
import 'package:desk_droid/features/mcp/domain/entities/mcp_ocr_element.dart';

/// Pure TSV parser transforming Tesseract stdout into structured [McpOcrElement]s.
class McpTesseractParser {
  const McpTesseractParser();

  /// Parses TSV string into both line-level and word-level [McpOcrElement]s.
  List<McpOcrElement> parseTsv(String tsvContent) {
    if (tsvContent.trim().isEmpty) return const [];

    final lines = tsvContent.splitLines();
    final words = <_TesseractWord>[];

    for (final line in lines) {
      final cols = line.split('\t');
      if (cols.length < 12) continue;

      final level = int.tryParse(cols[0]);
      if (level != 5) continue; // Level 5 is word level

      final text = cols[11].trim();
      if (text.isEmpty) continue;

      final conf = double.tryParse(cols[10]) ?? -1.0;
      if (conf <= 0) continue;

      final left = int.tryParse(cols[6]) ?? 0;
      final top = int.tryParse(cols[7]) ?? 0;
      final width = int.tryParse(cols[8]) ?? 0;
      final height = int.tryParse(cols[9]) ?? 0;

      final blockNum = int.tryParse(cols[2]) ?? 0;
      final parNum = int.tryParse(cols[3]) ?? 0;
      final lineNum = int.tryParse(cols[4]) ?? 0;
      final wordNum = int.tryParse(cols[5]) ?? 0;

      words.add(
        _TesseractWord(
          text: text,
          left: left,
          top: top,
          width: width,
          height: height,
          confidence: conf / 100.0,
          blockNum: blockNum,
          parNum: parNum,
          lineNum: lineNum,
          wordNum: wordNum,
        ),
      );
    }

    if (words.isEmpty) return const [];

    final results = <McpOcrElement>[];

    // Group words by block, paragraph, and line to assemble phrase elements
    final lineGroups = <String, List<_TesseractWord>>{};
    for (final word in words) {
      final key = '${word.blockNum}:${word.parNum}:${word.lineNum}';
      lineGroups.putIfAbsent(key, () => []).add(word);
    }

    for (final group in lineGroups.values) {
      if (group.length > 1) {
        group.sort((a, b) => a.wordNum.compareTo(b.wordNum));
        final lineText = group.map((w) => w.text).join(' ');
        final left = group.map((w) => w.left).reduce(min);
        final top = group.map((w) => w.top).reduce(min);
        final right = group.map((w) => w.left + w.width).reduce(max);
        final bottom = group.map((w) => w.top + w.height).reduce(max);
        final avgConf =
            group.map((w) => w.confidence).reduce((a, b) => a + b) /
            group.length;

        results.add(
          McpOcrElement(
            text: lineText,
            left: left,
            top: top,
            width: right - left,
            height: bottom - top,
            confidence: avgConf,
          ),
        );
      }
    }

    // Append individual word elements
    for (final word in words) {
      results.add(
        McpOcrElement(
          text: word.text,
          left: word.left,
          top: word.top,
          width: word.width,
          height: word.height,
          confidence: word.confidence,
        ),
      );
    }

    return results;
  }
}

class _TesseractWord {
  const _TesseractWord({
    required this.text,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.confidence,
    required this.blockNum,
    required this.parNum,
    required this.lineNum,
    required this.wordNum,
  });

  final String text;
  final int left;
  final int top;
  final int width;
  final int height;
  final double confidence;
  final int blockNum;
  final int parNum;
  final int lineNum;
  final int wordNum;
}
