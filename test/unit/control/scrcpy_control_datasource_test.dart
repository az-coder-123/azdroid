import 'dart:typed_data';

import 'package:desk_droid/core/services/scrcpy_control_message.dart';
import 'package:desk_droid/features/control/data/datasources/control_datasource.dart';
import 'package:desk_droid/features/control/data/datasources/fallback_control_datasource.dart';
import 'package:desk_droid/features/control/data/datasources/scrcpy_control_datasource.dart';
import 'package:desk_droid/features/control/domain/entities/frame_size.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fake_control_channel.dart';

class MockControlDatasource extends Mock implements ControlDatasource {}

void main() {
  const serial = '192.168.1.3:5555';
  const frame = FrameSize(1080, 2336);
  late FakeControlChannel channel;
  late ScrcpyControlDatasource scrcpy;

  setUp(() {
    channel = FakeControlChannel(connectedSerial: serial);
    scrcpy = ScrcpyControlDatasource(channel: channel, delay: (_) async {});
  });

  int actionOf(Uint8List m) => m[1];
  int typeOf(Uint8List m) => m[0];

  group('ScrcpyControlDatasource', () {
    test(
      'tap sends DOWN then UP at the same position with the frame size',
      () async {
        expect(await scrcpy.injectTap(serial, 540, 1168, frame: frame), isTrue);

        expect(channel.sent, [
          ScrcpyControlMessage.touch(
            action: ScrcpyControlMessage.actionDown,
            x: 540,
            y: 1168,
            screenWidth: 1080,
            screenHeight: 2336,
          ),
          ScrcpyControlMessage.touch(
            action: ScrcpyControlMessage.actionUp,
            x: 540,
            y: 1168,
            screenWidth: 1080,
            screenHeight: 2336,
            pressure: 0,
          ),
        ]);
      },
    );

    test('swipe sends DOWN, interpolated MOVEs, then UP at the end', () async {
      expect(
        await scrcpy.injectSwipe(serial, 100, 2000, 100, 400, 64, frame: frame),
        isTrue,
      );

      final actions = channel.sent.map(actionOf).toList();
      expect(actions.first, ScrcpyControlMessage.actionDown);
      expect(actions.last, ScrcpyControlMessage.actionUp);
      // 64 ms at 16 ms per move = 4 moves.
      expect(
        actions.where((a) => a == ScrcpyControlMessage.actionMove),
        hasLength(4),
      );
      final lastMove = channel.sent[channel.sent.length - 2];
      expect(ByteData.sublistView(lastMove).getInt32(14), 400);
    });

    test('keyevent sends key DOWN then UP', () async {
      expect(await scrcpy.injectKeyevent(serial, 3), isTrue);
      expect(channel.sent.map(typeOf), [0, 0]);
      expect(channel.sent.map(actionOf), [0, 1]);
    });

    test(
      'declines without a frame size, another device, or no socket',
      () async {
        expect(await scrcpy.injectTap(serial, 1, 1), isFalse);
        expect(
          await scrcpy.injectTap('other:5555', 1, 1, frame: frame),
          isFalse,
        );
        channel.connectedSerial = null;
        expect(await scrcpy.injectKeyevent(serial, 3), isFalse);
        expect(channel.sent, isEmpty);
      },
    );

    test('pastes non-ASCII text through the device clipboard', () async {
      expect(await scrcpy.injectText(serial, 'Xin chào 你好 👋'), isTrue);
      expect(channel.sent.single, [
        ...ScrcpyControlMessage.setClipboard(
          text: 'Xin chào 你好 👋',
          paste: true,
        ),
      ]);
      expect(
        typeOf(channel.sent.single),
        ScrcpyControlMessage.typeSetClipboard,
      );
    });

    test('leaves ASCII text to adb, keeping the device clipboard', () async {
      expect(await scrcpy.injectText(serial, 'hello world 123'), isFalse);
      expect(channel.sent, isEmpty);
    });

    test('does not paste for another device or a closed socket', () async {
      expect(await scrcpy.injectText('other:5555', 'chào'), isFalse);
      channel.connectedSerial = null;
      expect(await scrcpy.injectText(serial, 'chào'), isFalse);
      expect(channel.sent, isEmpty);
    });
  });

  group('FallbackControlDatasource', () {
    late MockControlDatasource adb;
    late FallbackControlDatasource datasource;

    setUp(() {
      adb = MockControlDatasource();
      datasource = FallbackControlDatasource(primary: scrcpy, fallback: adb);
      when(() => adb.injectTap(any(), any(), any(), frame: any(named: 'frame')))
          .thenAnswer((_) async => true);
      when(() => adb.injectText(any(), any())).thenAnswer((_) async => true);
    });

    setUpAll(() => registerFallbackValue(const FrameSize(1, 1)));

    test('uses the control socket while it is connected', () async {
      await datasource.injectTap(serial, 10, 20, frame: frame);
      expect(channel.sent, hasLength(2));
      verifyNever(
        () => adb.injectTap(any(), any(), any(), frame: any(named: 'frame')),
      );
    });

    test('falls back to adb when the socket is closed', () async {
      channel.connectedSerial = null;
      await datasource.injectTap(serial, 10, 20, frame: frame);
      verify(() => adb.injectTap(serial, 10, 20, frame: frame)).called(1);
    });

    test('pastes non-ASCII text without touching adb', () async {
      expect(await datasource.injectText(serial, 'Xin chào'), isTrue);
      expect(channel.sent, hasLength(1));
      verifyNever(() => adb.injectText(any(), any()));
    });

    test('types ASCII text through adb', () async {
      await datasource.injectText(serial, 'hello');
      verify(() => adb.injectText(serial, 'hello')).called(1);
    });

    test(
      'falls back to adb for non-ASCII text when the socket is closed',
      () async {
        channel.connectedSerial = null;
        await datasource.injectText(serial, 'Xin chào');
        verify(() => adb.injectText(serial, 'Xin chào')).called(1);
      },
    );
  });
}
