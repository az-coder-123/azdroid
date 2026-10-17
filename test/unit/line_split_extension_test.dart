import 'package:desk_droid/core/extensions/line_split_extension.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LineSplit.splitLines', () {
    test('handles LF output', () {
      expect('a\nb\n'.splitLines(), ['a', 'b']);
    });

    test('strips CR from Windows CRLF output', () {
      expect('List of devices attached\r\nabc\tdevice\r\n'.splitLines(), [
        'List of devices attached',
        'abc\tdevice',
      ]);
    });

    test('keeps blank lines between content', () {
      expect('a\r\n\r\nb'.splitLines(), ['a', '', 'b']);
    });

    test('returns an empty list for empty input', () {
      expect(''.splitLines(), isEmpty);
    });
  });
}
