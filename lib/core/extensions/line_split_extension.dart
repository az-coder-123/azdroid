import 'dart:convert';

/// Splits command output into lines regardless of line endings.
///
/// Pure Dart (no Flutter) so the MCP server can use it.
extension LineSplit on String {
  /// Lines split on `\n`, `\r\n`, or `\r`, without line terminators.
  ///
  /// Unlike `split('\n')`, Windows output does not leave a trailing `\r`
  /// on each line, and a final terminator does not add an empty line.
  List<String> splitLines() => const LineSplitter().convert(this);
}
