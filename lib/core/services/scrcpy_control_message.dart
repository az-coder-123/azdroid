import 'dart:convert';
import 'dart:typed_data';

/// Serializes scrcpy control messages (client -> server); types 0-17 are
/// identical from v3.3.x through v5.0.x.
///
/// Byte layouts mirror `app/src/control_msg.c` and are checked against the
/// scrcpy project's own serialization tests (see the unit tests). All
/// integers are big-endian. Positions use video-frame coordinates plus the
/// frame size; the server ignores events whose size differs from its
/// current video size.
class ScrcpyControlMessage {
  const ScrcpyControlMessage._();

  static const int typeInjectKeycode = 0;
  static const int typeInjectText = 1;
  static const int typeInjectTouchEvent = 2;
  static const int typeInjectScrollEvent = 3;
  static const int typeBackOrScreenOn = 4;
  static const int typeSetClipboard = 9;
  static const int typeSetDisplayPower = 10;

  /// Android `KeyEvent` / `MotionEvent` actions used by DeskDroid.
  static const int actionDown = 0;
  static const int actionUp = 1;
  static const int actionMove = 2;

  /// Pointer id of a single finger that is not a real device touch.
  static const int pointerIdGenericFinger = -2;

  /// Pointer id of the second, simulated finger of a pinch (scrcpy's own
  /// client uses it the same way).
  static const int pointerIdVirtualFinger = -3;

  /// Longest text payload the server accepts in one message, in UTF-8 bytes.
  static const int maxTextBytes = 300;

  /// Longest clipboard text the server accepts, in UTF-8 bytes: its
  /// 256 KiB message limit minus the 14-byte header.
  static const int maxClipboardBytes = (1 << 18) - 14;

  /// Sequence number that asks the server for no acknowledgement.
  static const int sequenceNoAck = 0;

  /// Key down/up event (14 bytes).
  static Uint8List keycode({
    required int action,
    required int keyCode,
    int repeat = 0,
    int metaState = 0,
  }) {
    final data = ByteData(14)
      ..setUint8(0, typeInjectKeycode)
      ..setUint8(1, action)
      ..setInt32(2, keyCode)
      ..setInt32(6, repeat)
      ..setInt32(10, metaState);
    return data.buffer.asUint8List();
  }

  /// Text typed through the device key map (5 + n bytes). Text longer than
  /// [maxTextBytes] is cut at a UTF-8 character boundary.
  static Uint8List text(String text) {
    final bytes = _truncateUtf8(utf8.encode(text), maxTextBytes);
    final builder = BytesBuilder(copy: false)
      ..addByte(typeInjectText)
      ..add(_uint32(bytes.length))
      ..add(bytes);
    return builder.takeBytes();
  }

  /// Sets the device clipboard to [text] (14 + n bytes); with [paste] the
  /// server then presses PASTE into the focused field (Android 7+). Text
  /// longer than [maxClipboardBytes] is cut at a UTF-8 character boundary.
  static Uint8List setClipboard({
    required String text,
    bool paste = false,
    int sequence = sequenceNoAck,
  }) {
    final bytes = _truncateUtf8(utf8.encode(text), maxClipboardBytes);
    final header = ByteData(10)
      ..setUint8(0, typeSetClipboard)
      ..setUint64(1, sequence)
      ..setUint8(9, paste ? 1 : 0);
    final builder = BytesBuilder(copy: false)
      ..add(header.buffer.asUint8List())
      ..add(_uint32(bytes.length))
      ..add(bytes);
    return builder.takeBytes();
  }

  /// Touch event at ([x], [y]) in a [screenWidth] x [screenHeight] frame
  /// (32 bytes). [pressure] is 0.0 to 1.0.
  static Uint8List touch({
    required int action,
    required int x,
    required int y,
    required int screenWidth,
    required int screenHeight,
    int pointerId = pointerIdGenericFinger,
    double pressure = 1.0,
    int actionButton = 0,
    int buttons = 0,
  }) {
    final data = ByteData(32)
      ..setUint8(0, typeInjectTouchEvent)
      ..setUint8(1, action)
      ..setInt64(2, pointerId);
    _writePosition(data, 10, x, y, screenWidth, screenHeight);
    data
      ..setUint16(22, floatToU16FixedPoint(pressure))
      ..setInt32(24, actionButton)
      ..setInt32(28, buttons);
    return data.buffer.asUint8List();
  }

  /// Scroll event (21 bytes). [hScroll] and [vScroll] are in -16..16.
  static Uint8List scroll({
    required int x,
    required int y,
    required int screenWidth,
    required int screenHeight,
    required double hScroll,
    required double vScroll,
    int buttons = 0,
  }) {
    final data = ByteData(21)..setUint8(0, typeInjectScrollEvent);
    _writePosition(data, 1, x, y, screenWidth, screenHeight);
    data
      ..setInt16(13, floatToI16FixedPoint((hScroll / 16).clamp(-1.0, 1.0)))
      ..setInt16(15, floatToI16FixedPoint((vScroll / 16).clamp(-1.0, 1.0)))
      ..setInt32(17, buttons);
    return data.buffer.asUint8List();
  }

  /// BACK, or power the screen on when it is off (2 bytes).
  static Uint8List backOrScreenOn(int action) =>
      Uint8List.fromList([typeBackOrScreenOn, action]);

  /// Turns the physical display panel on or off (2 bytes). Off keeps the
  /// device awake and mirroring; the server turns the panel back on when it
  /// exits (with `cleanup=true`).
  static Uint8List setDisplayPower({required bool on}) =>
      Uint8List.fromList([typeSetDisplayPower, on ? 1 : 0]);

  /// `sc_float_to_u16fp`: 0.0..1.0 to u16, with 1.0 mapped to 0xFFFF.
  static int floatToU16FixedPoint(double value) {
    assert(value >= 0 && value <= 1, 'pressure out of range: $value');
    final scaled = (value * 0x10000).toInt();
    return scaled >= 0xFFFF ? 0xFFFF : scaled;
  }

  /// `sc_float_to_i16fp`: -1.0..1.0 to i16, with 1.0 mapped to 0x7FFF.
  static int floatToI16FixedPoint(double value) {
    assert(value >= -1 && value <= 1, 'value out of range: $value');
    final scaled = (value * 0x8000).toInt();
    return scaled >= 0x7FFF ? 0x7FFF : scaled;
  }

  static void _writePosition(
    ByteData data,
    int offset,
    int x,
    int y,
    int screenWidth,
    int screenHeight,
  ) {
    data
      ..setInt32(offset, x)
      ..setInt32(offset + 4, y)
      ..setUint16(offset + 8, screenWidth)
      ..setUint16(offset + 10, screenHeight);
  }

  static Uint8List _uint32(int value) =>
      (ByteData(4)..setUint32(0, value)).buffer.asUint8List();

  /// Cuts [bytes] to at most [max] bytes without splitting a UTF-8 sequence.
  static List<int> _truncateUtf8(List<int> bytes, int max) {
    if (bytes.length <= max) return bytes;
    var end = max;
    // Continuation bytes look like 10xxxxxx; back up to a character start.
    while (end > 0 && (bytes[end] & 0xC0) == 0x80) {
      end--;
    }
    return bytes.sublist(0, end);
  }
}
