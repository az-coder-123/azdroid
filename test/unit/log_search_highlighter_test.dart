import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:desk_droid/features/logging/presentation/utils/log_search_highlighter.dart';

void main() {
  group('LogSearchHighlighter Unit Tests', () {
    const baseStyle = TextStyle(fontSize: 11, color: Colors.grey);
    const highlightColor = Colors.amber;

    test('Returns single base span when query is empty or whitespace', () {
      final spans = LogSearchHighlighter.buildSpans(
        text: 'Android runtime started',
        query: '   ',
        baseStyle: baseStyle,
        highlightColor: highlightColor,
      );

      expect(spans.length, 1);
      expect(spans.first.text, 'Android runtime started');
      expect(spans.first.style, baseStyle);
    });

    test('Returns single base span when no match is found', () {
      final spans = LogSearchHighlighter.buildSpans(
        text: 'Android runtime started',
        query: 'ActivityManager',
        baseStyle: baseStyle,
        highlightColor: highlightColor,
      );

      expect(spans.length, 1);
      expect(spans.first.text, 'Android runtime started');
    });

    test('Splits matching substring with highlighted style', () {
      final spans = LogSearchHighlighter.buildSpans(
        text: 'FatalException in thread main',
        query: 'Exception',
        baseStyle: baseStyle,
        highlightColor: highlightColor,
      );

      expect(spans.length, 3);
      expect(spans[0].text, 'Fatal');
      expect(spans[0].style, baseStyle);

      expect(spans[1].text, 'Exception');
      expect(spans[1].style!.fontWeight, FontWeight.bold);

      expect(spans[2].text, ' in thread main');
      expect(spans[2].style, baseStyle);
    });

    test('Highlights multiple occurrences', () {
      final spans = LogSearchHighlighter.buildSpans(
        text: 'tag: wifi, state: wifi_connected',
        query: 'wifi',
        baseStyle: baseStyle,
        highlightColor: highlightColor,
      );

      // Matches: "tag: " + "wifi" + ", state: " + "wifi" + "_connected" -> 5 spans
      expect(spans.length, 5);
      expect(spans[1].text, 'wifi');
      expect(spans[3].text, 'wifi');
    });

    test('Respects caseSensitive flag', () {
      final caseInsensitiveSpans = LogSearchHighlighter.buildSpans(
        text: 'Error and error',
        query: 'error',
        baseStyle: baseStyle,
        highlightColor: highlightColor,
        caseSensitive: false,
      );
      expect(caseInsensitiveSpans.length, 3);
      expect(caseInsensitiveSpans[0].text, 'Error');
      expect(caseInsensitiveSpans[1].text, ' and ');
      expect(caseInsensitiveSpans[2].text, 'error');

      final caseSensitiveSpans = LogSearchHighlighter.buildSpans(
        text: 'Error and error',
        query: 'error',
        baseStyle: baseStyle,
        highlightColor: highlightColor,
        caseSensitive: true,
      );
      // Only the lowercase "error" matches
      expect(caseSensitiveSpans.length, 2);
      expect(caseSensitiveSpans[0].text, 'Error and ');
      expect(caseSensitiveSpans[1].text, 'error');
    });

    test('Handles special regex characters cleanly when isRegex is false', () {
      final spans = LogSearchHighlighter.buildSpans(
        text: 'NetworkRequest [ TRACK_DEFAULT id=123 ]',
        query: '[ TRACK_DEFAULT',
        baseStyle: baseStyle,
        highlightColor: highlightColor,
        isRegex: false,
      );

      expect(spans.length, 3);
      expect(spans[1].text, '[ TRACK_DEFAULT');
    });
  });
}
