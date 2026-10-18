import 'dart:typed_data';

import 'package:desk_droid/core/services/scrcpy_control_message.dart';
import 'package:desk_droid/features/control/data/datasources/adb_touch_stream_adapter.dart';
import 'package:desk_droid/features/control/data/datasources/control_datasource.dart';
import 'package:desk_droid/features/control/data/datasources/fallback_control_datasource.dart';
import 'package:desk_droid/features/control/data/datasources/scrcpy_control_datasource.dart';
import 'package:desk_droid/features/control/domain/entities/frame_size.dart';
import 'package:desk_droid/features/control/domain/entities/touch_stream.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fake_control_channel.dart';

class _MockAdb extends Mock implements ControlDatasource {}

void main() {
  const serial = '192.168.1.3:5555';
  const frame = FrameSize(1080, 2336);
  const a = (x: 300, y: 1000);
  const b = (x: 780, y: 1336);
  late FakeControlChannel channel;
  late ScrcpyControlDatasource scrcpy;

  setUp(() {
    channel = FakeControlChannel(connectedSerial: serial);
    scrcpy = ScrcpyControlDatasource(channel: channel, delay: (_) async {});
  });

  setUpAll(() => registerFallbackValue(const FrameSize(1, 1)));

  // Touch message layout: type, action, pointer id (8), x, y, w, h, pressure.
  int action(Uint8List m) => m[1];
  int pointerId(Uint8List m) => ByteData.sublistView(m).getInt64(2);
  int x(Uint8List m) => ByteData.sublistView(m).getInt32(10);
  int pressure(Uint8List m) => ByteData.sublistView(m).getUint16(22);

  group('ScrcpyControlDatasource touch stream', () {
    test('two fingers use the generic and the virtual finger ids', () async {
      for (final phase in TouchStreamPhase.values) {
        expect(
          await scrcpy.injectTouchStream(serial, phase, [a, b], frame: frame),
          isTrue,
        );
      }

      expect(channel.sent.map(action), [0, 0, 2, 2, 1, 1]);
      expect(channel.sent.map(pointerId), [-2, -3, -2, -3, -2, -3]);
      expect(channel.sent.map(x), [300, 780, 300, 780, 300, 780]);
      expect(pressure(channel.sent[4]), 0); // UP lifts with no pressure.
      expect(
        channel.sent.map((m) => m.first),
        everyElement(ScrcpyControlMessage.typeInjectTouchEvent),
      );
    });

    test('end without points lifts the fingers where they are', () async {
      await scrcpy.injectTouchStream(serial, TouchStreamPhase.start, [
        a,
      ], frame: frame);
      await scrcpy.injectTouchStream(serial, TouchStreamPhase.move, [
        b,
      ], frame: frame);
      await scrcpy.injectTouchStream(
        serial,
        TouchStreamPhase.end,
        [],
        frame: frame,
      );

      expect(action(channel.sent.last), ScrcpyControlMessage.actionUp);
      expect(x(channel.sent.last), b.x);
    });

    test('declines without a frame, a socket, or with three fingers', () async {
      expect(
        await scrcpy.injectTouchStream(serial, TouchStreamPhase.start, [a]),
        isFalse,
      );
      expect(
        await scrcpy.injectTouchStream(serial, TouchStreamPhase.start, [
          a,
          b,
          a,
        ], frame: frame),
        isFalse,
      );
      channel.connectedSerial = null;
      expect(
        await scrcpy.injectTouchStream(serial, TouchStreamPhase.start, [
          a,
        ], frame: frame),
        isFalse,
      );
      expect(channel.sent, isEmpty);
    });
  });

  group('AdbTouchStreamAdapter', () {
    late _MockAdb adb;
    late AdbTouchStreamAdapter adapter;

    setUp(() {
      adb = _MockAdb();
      adapter = AdbTouchStreamAdapter(adb);
      when(() => adb.injectTap(any(), any(), any(), frame: any(named: 'frame')))
          .thenAnswer((_) async => true);
      when(
        () => adb.injectSwipe(
          any(),
          any(),
          any(),
          any(),
          any(),
          any(),
          frame: any(named: 'frame'),
        ),
      ).thenAnswer((_) async => true);
    });

    test(
      'one finger becomes a swipe from start to the last position',
      () async {
        await adapter.handle(serial, TouchStreamPhase.start, [a]);
        await adapter.handle(serial, TouchStreamPhase.move, [b]);
        expect(await adapter.handle(serial, TouchStreamPhase.end, []), isTrue);

        verify(
          () => adb.injectSwipe(serial, a.x, a.y, b.x, b.y, any(), frame: null),
        ).called(1);
      },
    );

    test('a finger that did not move becomes a tap', () async {
      await adapter.handle(serial, TouchStreamPhase.start, [a]);
      await adapter.handle(serial, TouchStreamPhase.end, [a]);

      verify(() => adb.injectTap(serial, a.x, a.y, frame: null)).called(1);
    });

    test('two fingers cannot be replayed over adb', () async {
      expect(
        await adapter.handle(serial, TouchStreamPhase.start, [a, b]),
        isFalse,
      );
      expect(await adapter.handle(serial, TouchStreamPhase.end, []), isFalse);
      verifyZeroInteractions(adb);
    });
  });

  group('FallbackControlDatasource touch stream', () {
    late _MockAdb adb;
    late FallbackControlDatasource datasource;

    setUp(() {
      adb = _MockAdb();
      datasource = FallbackControlDatasource(primary: scrcpy, fallback: adb);
      when(
        () => adb.injectTouchStream(
          any(),
          any(),
          any(),
          frame: any(named: 'frame'),
        ),
      ).thenAnswer((_) async => true);
    });

    setUpAll(() => registerFallbackValue(TouchStreamPhase.start));

    test('a stream that starts on the socket stays on it', () async {
      await datasource.injectTouchStream(serial, TouchStreamPhase.start, [
        a,
      ], frame: frame);
      await datasource.injectTouchStream(serial, TouchStreamPhase.end, [
        a,
      ], frame: frame);

      expect(channel.sent, hasLength(2));
      verifyNever(
        () => adb.injectTouchStream(
          any(),
          any(),
          any(),
          frame: any(named: 'frame'),
        ),
      );
    });

    test(
      'a stream that cannot start on the socket goes to adb whole',
      () async {
        channel.connectedSerial = null;
        await datasource.injectTouchStream(serial, TouchStreamPhase.start, [
          a,
        ], frame: frame);
        // The socket coming back mid-gesture must not split the stream.
        channel.connectedSerial = serial;
        await datasource.injectTouchStream(serial, TouchStreamPhase.end, [
          b,
        ], frame: frame);

        expect(channel.sent, isEmpty);
        verify(() => adb.injectTouchStream(serial, any(), any(), frame: frame))
            .called(2);
      },
    );
  });
}
