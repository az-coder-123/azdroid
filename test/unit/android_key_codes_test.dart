import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:desk_droid/core/constants/android_key_codes.dart';

void main() {
  group('AndroidKeyCodes', () {
    test('correctly maps navigation and editing keys', () {
      expect(
        AndroidKeyCodes.mapLogicalKey(LogicalKeyboardKey.backspace),
        AndroidKeyCodes.keycodeDel,
      );
      expect(
        AndroidKeyCodes.mapLogicalKey(LogicalKeyboardKey.delete),
        AndroidKeyCodes.keycodeForwardDel,
      );
      expect(
        AndroidKeyCodes.mapLogicalKey(LogicalKeyboardKey.enter),
        AndroidKeyCodes.keycodeEnter,
      );
      expect(
        AndroidKeyCodes.mapLogicalKey(LogicalKeyboardKey.escape),
        AndroidKeyCodes.keycodeEscape,
      );
      expect(
        AndroidKeyCodes.mapLogicalKey(LogicalKeyboardKey.tab),
        AndroidKeyCodes.keycodeTab,
      );
      expect(
        AndroidKeyCodes.mapLogicalKey(LogicalKeyboardKey.space),
        AndroidKeyCodes.keycodeSpace,
      );
    });

    test('correctly maps directional arrow keys to D-Pad', () {
      expect(
        AndroidKeyCodes.mapLogicalKey(LogicalKeyboardKey.arrowUp),
        AndroidKeyCodes.keycodeDpadUp,
      );
      expect(
        AndroidKeyCodes.mapLogicalKey(LogicalKeyboardKey.arrowDown),
        AndroidKeyCodes.keycodeDpadDown,
      );
      expect(
        AndroidKeyCodes.mapLogicalKey(LogicalKeyboardKey.arrowLeft),
        AndroidKeyCodes.keycodeDpadLeft,
      );
      expect(
        AndroidKeyCodes.mapLogicalKey(LogicalKeyboardKey.arrowRight),
        AndroidKeyCodes.keycodeDpadRight,
      );
    });

    test('correctly maps digit and letter keys', () {
      expect(
        AndroidKeyCodes.mapLogicalKey(LogicalKeyboardKey.digit0),
        AndroidKeyCodes.keycode0,
      );
      expect(
        AndroidKeyCodes.mapLogicalKey(LogicalKeyboardKey.digit9),
        AndroidKeyCodes.keycode9,
      );
      expect(
        AndroidKeyCodes.mapLogicalKey(LogicalKeyboardKey.keyA),
        AndroidKeyCodes.keycodeA,
      );
      expect(
        AndroidKeyCodes.mapLogicalKey(LogicalKeyboardKey.keyZ),
        AndroidKeyCodes.keycodeZ,
      );
    });
  });
}
