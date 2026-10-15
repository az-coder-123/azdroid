import 'package:flutter/material.dart';

/// Pure utility that builds highlighted TextSpan lists for matching search queries.
class LogSearchHighlighter {
  const LogSearchHighlighter._();

  /// Builds a list of [TextSpan]s highlighting occurrences of [query] in [text].
  static List<TextSpan> buildSpans({
    required String text,
    required String query,
    required TextStyle baseStyle,
    required Color highlightColor,
    bool caseSensitive = false,
    bool isRegex = false,
  }) {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty || text.isEmpty) {
      return [TextSpan(text: text, style: baseStyle)];
    }

    RegExp regExp;
    try {
      regExp = isRegex
          ? RegExp(trimmedQuery, caseSensitive: caseSensitive)
          : RegExp(RegExp.escape(trimmedQuery), caseSensitive: caseSensitive);
    } catch (_) {
      // Fallback for invalid regex while user is still typing
      regExp = RegExp(
        RegExp.escape(trimmedQuery),
        caseSensitive: caseSensitive,
      );
    }

    final matches = regExp.allMatches(text).toList();
    if (matches.isEmpty) {
      return [TextSpan(text: text, style: baseStyle)];
    }

    final spans = <TextSpan>[];
    int cursor = 0;

    final highlightStyle = baseStyle.copyWith(
      backgroundColor: highlightColor.withValues(alpha: 0.38),
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );

    for (final match in matches) {
      if (match.start > cursor) {
        spans.add(
          TextSpan(text: text.substring(cursor, match.start), style: baseStyle),
        );
      }
      spans.add(
        TextSpan(
          text: text.substring(match.start, match.end),
          style: highlightStyle,
        ),
      );
      cursor = match.end;
    }

    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor), style: baseStyle));
    }

    return spans;
  }
}
