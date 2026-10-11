import 'package:flutter/services.dart';

/// Comprehensive Android KeyEvent keycode constants and Flutter keyboard event mapping.
///
/// Corresponds to standard Android KeyEvent codes (`android.view.KeyEvent`).
class AndroidKeyCodes {
  const AndroidKeyCodes._();

  // Navigation
  static const int keycodeUnknown = 0;
  static const int keycodeHome = 3;
  static const int keycodeBack = 4;
  static const int keycodeCall = 5;
  static const int keycodeEndcall = 6;
  static const int keycodeVolumeUp = 24;
  static const int keycodeVolumeDown = 25;
  static const int keycodePower = 26;
  static const int keycodeCamera = 27;
  static const int keycodeClear = 28;
  static const int keycodeAppSwitch = 187;
  static const int keycodeMenu = 82;
  static const int keycodeSearch = 84;

  // D-Pad
  static const int keycodeDpadUp = 19;
  static const int keycodeDpadDown = 20;
  static const int keycodeDpadLeft = 21;
  static const int keycodeDpadRight = 22;
  static const int keycodeDpadCenter = 23;

  // Editing & Navigation
  static const int keycodeTab = 61;
  static const int keycodeSpace = 62;
  static const int keycodeEnter = 66;
  static const int keycodeDel = 67; // Backspace
  static const int keycodeForwardDel = 112; // Delete
  static const int keycodeEscape = 111;
  static const int keycodeMoveHome = 122;
  static const int keycodeMoveEnd = 123;
  static const int keycodePageUp = 92;
  static const int keycodePageDown = 93;

  // Modifiers
  static const int keycodeShiftLeft = 59;
  static const int keycodeShiftRight = 60;
  static const int keycodeCtrlLeft = 113;
  static const int keycodeCtrlRight = 114;
  static const int keycodeAltLeft = 57;
  static const int keycodeAltRight = 58;

  // Numbers (0 = 7, 1 = 8, ..., 9 = 16)
  static const int keycode0 = 7;
  static const int keycode1 = 8;
  static const int keycode2 = 9;
  static const int keycode3 = 10;
  static const int keycode4 = 11;
  static const int keycode5 = 12;
  static const int keycode6 = 13;
  static const int keycode7 = 14;
  static const int keycode8 = 15;
  static const int keycode9 = 16;

  // Letters (A = 29, ..., Z = 54)
  static const int keycodeA = 29;
  static const int keycodeB = 30;
  static const int keycodeC = 31;
  static const int keycodeD = 32;
  static const int keycodeE = 33;
  static const int keycodeF = 34;
  static const int keycodeG = 35;
  static const int keycodeH = 36;
  static const int keycodeI = 37;
  static const int keycodeJ = 38;
  static const int keycodeK = 39;
  static const int keycodeL = 40;
  static const int keycodeM = 41;
  static const int keycodeN = 42;
  static const int keycodeO = 43;
  static const int keycodeP = 44;
  static const int keycodeQ = 45;
  static const int keycodeR = 46;
  static const int keycodeS = 47;
  static const int keycodeT = 48;
  static const int keycodeU = 49;
  static const int keycodeV = 50;
  static const int keycodeW = 51;
  static const int keycodeX = 52;
  static const int keycodeY = 53;
  static const int keycodeZ = 54;

  // Media
  static const int keycodeMediaPlayPause = 85;
  static const int keycodeMediaStop = 86;
  static const int keycodeMediaNext = 87;
  static const int keycodeMediaPrevious = 88;
  static const int keycodeMute = 164;

  /// Maps a Flutter [LogicalKeyboardKey] to an Android KeyEvent keycode.
  /// Returns null if no direct single-key mapping exists.
  static int? mapLogicalKey(LogicalKeyboardKey key) {
    return switch (key) {
      LogicalKeyboardKey.backspace => keycodeDel,
      LogicalKeyboardKey.delete => keycodeForwardDel,
      LogicalKeyboardKey.enter ||
      LogicalKeyboardKey.numpadEnter => keycodeEnter,
      LogicalKeyboardKey.escape => keycodeEscape,
      LogicalKeyboardKey.tab => keycodeTab,
      LogicalKeyboardKey.space => keycodeSpace,

      // Arrows
      LogicalKeyboardKey.arrowUp => keycodeDpadUp,
      LogicalKeyboardKey.arrowDown => keycodeDpadDown,
      LogicalKeyboardKey.arrowLeft => keycodeDpadLeft,
      LogicalKeyboardKey.arrowRight => keycodeDpadRight,

      // Navigation
      LogicalKeyboardKey.home => keycodeMoveHome,
      LogicalKeyboardKey.end => keycodeMoveEnd,
      LogicalKeyboardKey.pageUp => keycodePageUp,
      LogicalKeyboardKey.pageDown => keycodePageDown,

      // Digits
      LogicalKeyboardKey.digit0 || LogicalKeyboardKey.numpad0 => keycode0,
      LogicalKeyboardKey.digit1 || LogicalKeyboardKey.numpad1 => keycode1,
      LogicalKeyboardKey.digit2 || LogicalKeyboardKey.numpad2 => keycode2,
      LogicalKeyboardKey.digit3 || LogicalKeyboardKey.numpad3 => keycode3,
      LogicalKeyboardKey.digit4 || LogicalKeyboardKey.numpad4 => keycode4,
      LogicalKeyboardKey.digit5 || LogicalKeyboardKey.numpad5 => keycode5,
      LogicalKeyboardKey.digit6 || LogicalKeyboardKey.numpad6 => keycode6,
      LogicalKeyboardKey.digit7 || LogicalKeyboardKey.numpad7 => keycode7,
      LogicalKeyboardKey.digit8 || LogicalKeyboardKey.numpad8 => keycode8,
      LogicalKeyboardKey.digit9 || LogicalKeyboardKey.numpad9 => keycode9,

      // Alphabet
      LogicalKeyboardKey.keyA => keycodeA,
      LogicalKeyboardKey.keyB => keycodeB,
      LogicalKeyboardKey.keyC => keycodeC,
      LogicalKeyboardKey.keyD => keycodeD,
      LogicalKeyboardKey.keyE => keycodeE,
      LogicalKeyboardKey.keyF => keycodeF,
      LogicalKeyboardKey.keyG => keycodeG,
      LogicalKeyboardKey.keyH => keycodeH,
      LogicalKeyboardKey.keyI => keycodeI,
      LogicalKeyboardKey.keyJ => keycodeJ,
      LogicalKeyboardKey.keyK => keycodeK,
      LogicalKeyboardKey.keyL => keycodeL,
      LogicalKeyboardKey.keyM => keycodeM,
      LogicalKeyboardKey.keyN => keycodeN,
      LogicalKeyboardKey.keyO => keycodeO,
      LogicalKeyboardKey.keyP => keycodeP,
      LogicalKeyboardKey.keyQ => keycodeQ,
      LogicalKeyboardKey.keyR => keycodeR,
      LogicalKeyboardKey.keyS => keycodeS,
      LogicalKeyboardKey.keyT => keycodeT,
      LogicalKeyboardKey.keyU => keycodeU,
      LogicalKeyboardKey.keyV => keycodeV,
      LogicalKeyboardKey.keyW => keycodeW,
      LogicalKeyboardKey.keyX => keycodeX,
      LogicalKeyboardKey.keyY => keycodeY,
      LogicalKeyboardKey.keyZ => keycodeZ,

      // Modifiers
      LogicalKeyboardKey.shiftLeft => keycodeShiftLeft,
      LogicalKeyboardKey.shiftRight => keycodeShiftRight,
      LogicalKeyboardKey.controlLeft => keycodeCtrlLeft,
      LogicalKeyboardKey.controlRight => keycodeCtrlRight,
      LogicalKeyboardKey.altLeft => keycodeAltLeft,
      LogicalKeyboardKey.altRight => keycodeAltRight,

      // Media
      LogicalKeyboardKey.audioVolumeUp => keycodeVolumeUp,
      LogicalKeyboardKey.audioVolumeDown => keycodeVolumeDown,
      LogicalKeyboardKey.audioVolumeMute => keycodeMute,

      _ => null,
    };
  }
}
