import 'package:desk_droid/features/mcp/data/services/mcp_tesseract_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = McpTesseractParser();

  group('McpTesseractParser Tests', () {
    test('returns empty list for blank or empty TSV content', () {
      expect(parser.parseTsv(''), isEmpty);
      expect(parser.parseTsv('   \n  \t  \n'), isEmpty);
    });

    test('ignores non-level-5 rows and log warnings', () {
      const tsv = '''
Estimating resolution as 300
level\tpage_num\tblock_num\tpar_num\tline_num\tword_num\tleft\ttop\twidth\theight\tconf\ttext
1\t1\t0\t0\t0\t0\t0\t0\t1080\t1920\t-1\t
2\t1\t1\t0\t0\t0\t100\t200\t500\t100\t-1\t
3\t1\t1\t1\t0\t0\t100\t200\t500\t100\t-1\t
4\t1\t1\t1\t1\t0\t100\t200\t500\t100\t-1\t
''';
      expect(parser.parseTsv(tsv), isEmpty);
    });

    test('parses single word and calculates accurate bounding box', () {
      const tsv = '''
level\tpage_num\tblock_num\tpar_num\tline_num\tword_num\tleft\ttop\twidth\theight\tconf\ttext
5\t1\t1\t1\t1\t1\t100\t200\t80\t40\t95.5\tSettings
''';
      final elements = parser.parseTsv(tsv);
      expect(elements.length, equals(1));

      final el = elements.first;
      expect(el.text, equals('Settings'));
      expect(el.left, equals(100));
      expect(el.top, equals(200));
      expect(el.width, equals(80));
      expect(el.height, equals(40));
      expect(el.centerX, equals(140));
      expect(el.centerY, equals(220));
      expect(el.confidence, closeTo(0.955, 0.001));
      expect(el.bounds, equals('[100,200][180,240]'));

      final map = el.toMap(screenWidth: 1000, screenHeight: 2000);
      expect(map['id'], equals(-1));
      expect(map['class'], equals('OcrTextElement'));
      expect(map['source'], equals('ocr_stage_3'));
      expect(map['centerPixels'], equals({'x': 140, 'y': 220}));
      expect(map['normalized'], equals({'x': 0.14, 'y': 0.11}));
    });

    test('merges multi-word lines into phrase elements before words', () {
      const tsv = '''
level\tpage_num\tblock_num\tpar_num\tline_num\tword_num\tleft\ttop\twidth\theight\tconf\ttext
5\t1\t1\t1\t1\t1\t50\t100\t80\t30\t90.0\tDisplay
5\t1\t1\t1\t1\t2\t140\t100\t90\t30\t96.0\tsettings
''';
      final elements = parser.parseTsv(tsv);
      // Expect 1 merged phrase + 2 individual words = 3 elements
      expect(elements.length, equals(3));

      final phrase = elements.first;
      expect(phrase.text, equals('Display settings'));
      expect(phrase.left, equals(50));
      expect(phrase.top, equals(100));
      expect(phrase.width, equals(180)); // from 50 to 140+90=230 -> 180
      expect(phrase.height, equals(30));
      expect(phrase.centerX, equals(140));
      expect(phrase.centerY, equals(115));
      expect(phrase.confidence, closeTo(0.93, 0.01));

      expect(elements[1].text, equals('Display'));
      expect(elements[2].text, equals('settings'));
    });
  });
}
