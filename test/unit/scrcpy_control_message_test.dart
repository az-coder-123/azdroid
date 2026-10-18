import 'dart:convert';
import 'dart:typed_data';

import 'package:desk_droid/core/services/scrcpy_control_message.dart';
import 'package:flutter_test/flutter_test.dart';

/// Expected bytes are copied from scrcpy v3.3.4
/// `app/tests/test_control_msg_serialize.c`, so DeskDroid serializes exactly
/// like the official client.
void main() {
  test('keycode matches test_serialize_inject_keycode', () {
    final bytes = ScrcpyControlMessage.keycode(
      action: ScrcpyControlMessage.actionUp,
      keyCode: 0x42, // AKEYCODE_ENTER
      repeat: 5,
      metaState: 0x41, // AMETA_SHIFT_ON | AMETA_SHIFT_LEFT_ON
    );
    expect(bytes, [
      0x00, 0x01, //
      0x00, 0x00, 0x00, 0x42,
      0x00, 0x00, 0x00, 0x05,
      0x00, 0x00, 0x00, 0x41,
    ]);
  });

  test('text matches test_serialize_inject_text', () {
    expect(ScrcpyControlMessage.text('hello, world!'), [
      0x01,
      0x00,
      0x00,
      0x00,
      0x0d,
      ...ascii.encode('hello, world!'),
    ]);
  });

  test('touch matches test_serialize_inject_touch_event', () {
    final bytes = ScrcpyControlMessage.touch(
      action: ScrcpyControlMessage.actionDown,
      pointerId: 0x1234567887654321,
      x: 100,
      y: 200,
      screenWidth: 1080,
      screenHeight: 1920,
      pressure: 1.0,
      actionButton: 1, // AMOTION_EVENT_BUTTON_PRIMARY
      buttons: 1,
    );
    expect(bytes, [
      0x02, 0x00, //
      0x12, 0x34, 0x56, 0x78, 0x87, 0x65, 0x43, 0x21,
      0x00, 0x00, 0x00, 0x64, 0x00, 0x00, 0x00, 0xc8,
      0x04, 0x38, 0x07, 0x80,
      0xff, 0xff,
      0x00, 0x00, 0x00, 0x01,
      0x00, 0x00, 0x00, 0x01,
    ]);
  });

  test('scroll matches test_serialize_inject_scroll_event', () {
    final bytes = ScrcpyControlMessage.scroll(
      x: 260,
      y: 1026,
      screenWidth: 1080,
      screenHeight: 1920,
      hScroll: 16,
      vScroll: -16,
      buttons: 1,
    );
    expect(bytes, [
      0x03,
      0x00,
      0x00,
      0x01,
      0x04,
      0x00,
      0x00,
      0x04,
      0x02,
      0x04,
      0x38,
      0x07,
      0x80,
      0x7F,
      0xFF,
      0x80,
      0x00,
      0x00,
      0x00,
      0x00,
      0x01,
    ]);
  });

  test('back_or_screen_on matches test_serialize_back_or_screen_on', () {
    expect(ScrcpyControlMessage.backOrScreenOn(ScrcpyControlMessage.actionUp), [
      0x04,
      0x01,
    ]);
  });

  test('set_clipboard matches test_serialize_set_clipboard', () {
    final bytes = ScrcpyControlMessage.setClipboard(
      text: 'hello, world!',
      paste: true,
      sequence: 0x0102030405060708,
    );
    expect(bytes, [
      0x09,
      0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, // sequence
      0x01, // paste
      0x00, 0x00, 0x00, 0x0d, // text length
      ...'hello, world!'.codeUnits,
    ]);
    expect(bytes, hasLength(27));
  });

  test('set_clipboard carries UTF-8 and asks for no ack by default', () {
    final bytes = ScrcpyControlMessage.setClipboard(text: 'Tiếng Việt');
    final text = utf8.encode('Tiếng Việt');
    expect(bytes.sublist(1, 9), List.filled(8, 0));
    expect(bytes[9], 0); // no paste
    expect(ByteData.sublistView(bytes, 10, 14).getUint32(0), text.length);
    expect(utf8.decode(bytes.sublist(14)), 'Tiếng Việt');
  });

  test('set_clipboard cuts long text at a character boundary', () {
    // 'ệ' is 3 bytes; the limit falls inside one of them.
    final long = 'a${'ệ' * (ScrcpyControlMessage.maxClipboardBytes ~/ 3)}';
    final bytes = ScrcpyControlMessage.setClipboard(text: long);
    final length = ByteData.sublistView(bytes, 10, 14).getUint32(0);
    expect(length, lessThanOrEqualTo(ScrcpyControlMessage.maxClipboardBytes));
    expect(() => utf8.decode(bytes.sublist(14)), returnsNormally);
    expect(bytes.length, 14 + length);
  });

  test('set_display_power matches test_serialize_set_display_power', () {
    expect(ScrcpyControlMessage.setDisplayPower(on: true), [0x0A, 0x01]);
    expect(ScrcpyControlMessage.setDisplayPower(on: false), [0x0A, 0x00]);
  });

  test('default touch uses the generic-finger pointer id (-2)', () {
    final bytes = ScrcpyControlMessage.touch(
      action: ScrcpyControlMessage.actionUp,
      x: 0,
      y: 0,
      screenWidth: 1,
      screenHeight: 1,
      pressure: 0,
    );
    expect(bytes.sublist(2, 10), [
      0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xfe, //
    ]);
    expect(bytes.sublist(22, 24), [0x00, 0x00]);
  });

  test('fixed point conversions follow scrcpy binary.h', () {
    expect(ScrcpyControlMessage.floatToU16FixedPoint(0.5), 0x8000);
    expect(ScrcpyControlMessage.floatToI16FixedPoint(-1), -0x8000);
    expect(ScrcpyControlMessage.floatToI16FixedPoint(0.5), 0x4000);
  });

  test('long text is cut at a UTF-8 boundary within 300 bytes', () {
    // 299 ASCII bytes, then "ệ" (3 bytes) would cross the limit.
    final text = '${'a' * 299}ệ tail';
    final bytes = ScrcpyControlMessage.text(text);
    final length =
        (bytes[1] << 24) | (bytes[2] << 16) | (bytes[3] << 8) | bytes[4];

    expect(length, 299);
    expect(utf8.decode(bytes.sublist(5)), 'a' * 299);
  });
}
