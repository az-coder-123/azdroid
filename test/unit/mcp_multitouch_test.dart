import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:desk_droid/core/constants/scrcpy_server_constants.dart';
import 'package:desk_droid/features/mcp/data/handlers/mcp_gesture_tool_executor.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_adb_client.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_scrcpy_touch_session.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_touch_player.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_unsupported_exception.dart';
import 'package:desk_droid/features/mcp/data/utils/mcp_argument_helper.dart';
import 'package:desk_droid/features/mcp/data/utils/mcp_gesture_strokes.dart';
import 'package:desk_droid/features/mcp/data/utils/mcp_touch_timeline.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAdb extends Mock implements McpAdbClient {}

/// A joystick held 0–400 ms while a second finger taps at 200 ms.
const _joystickAndTap = [
  {
    'points': [
      {'x': 0.2, 'y': 0.8, 't': 0},
      {'x': 0.3, 'y': 0.7, 't': 400},
    ],
  },
  {
    'points': [
      {'x': 0.9, 'y': 0.8, 't': 200},
    ],
    'holdMs': 80,
  },
];

void main() {
  group('timeline', () {
    test('two fingers overlap with their own ids and timing', () {
      final events = McpTouchTimeline.compile(
        McpTouchTimeline.parse(_joystickAndTap),
        1000,
        2000,
      );
      String key(McpTouchEvent e) => '${e.atMs}:${e.pointerId}:${e.action}';
      expect(
        events.first,
        const McpTouchEvent(0, 0, McpTouchEvent.down, 200, 1600),
      );
      expect(events.map(key), contains('200:1:0'));
      expect(events.map(key), contains('280:1:1'));
      expect(
        events.last,
        const McpTouchEvent(400, 0, McpTouchEvent.up, 300, 1400),
      );
      // Finger 0 is still down (moving) while finger 1 taps.
      final moves = events.where((e) => e.pointerId == 0 && e.action == 2);
      expect(moves.any((e) => e.atMs > 200 && e.atMs < 280), isTrue);
      // Ordered by time.
      for (var i = 1; i < events.length; i++) {
        expect(events[i].atMs, greaterThanOrEqualTo(events[i - 1].atMs));
      }
    });

    test('a zero-length tap still goes down before up', () {
      final events = McpTouchTimeline.compile(
        McpTouchTimeline.parse([
          {
            'points': [
              {'xPixel': 5, 'yPixel': 6, 't': 10},
            ],
            'holdMs': 0,
          },
        ]),
        100,
        100,
      );
      expect(events.map((e) => e.action), [
        McpTouchEvent.down,
        McpTouchEvent.up,
      ]);
    });

    test('rejects time going backwards, 11 fingers, and over a minute', () {
      Matcher fails(String text) => throwsA(
        isA<McpArgumentException>().having(
          (e) => e.message,
          'message',
          contains(text),
        ),
      );
      expect(
        () => McpTouchTimeline.parse([
          {
            'points': [
              {'x': 0.1, 'y': 0.1, 't': 100},
              {'x': 0.2, 'y': 0.2, 't': 50},
            ],
          },
        ]),
        fails('earlier'),
      );
      final eleven = [
        for (var i = 0; i < 11; i++)
          {
            'points': [
              {'x': 0.05 * i, 'y': 0.5, 't': 0},
            ],
            'holdMs': 100,
          },
      ];
      expect(
        () =>
            McpTouchTimeline.compile(McpTouchTimeline.parse(eleven), 100, 100),
        fails('More than 10 fingers'),
      );
      expect(
        () => McpTouchTimeline.compile(
          McpTouchTimeline.parse([
            {
              'points': [
                {'x': 0.5, 'y': 0.5, 't': 61000},
              ],
            },
          ]),
          100,
          100,
        ),
        fails('limit'),
      );
    });
  });

  test('pinch spreads two fingers to scale × the span', () {
    final strokes = McpGestureStrokes.pinch(
      center: (500, 1000),
      scale: 2,
      durationMs: 300,
    );
    double span(int i) {
      final a = strokes[0].points[i].point.toPixels(0, 0);
      final b = strokes[1].points[i].point.toPixels(0, 0);
      return sqrt(pow(a.$1 - b.$1, 2) + pow(a.$2 - b.$2, 2));
    }

    expect(span(0), closeTo(300, 2));
    expect(span(McpGestureStrokes.segments), closeTo(600, 2));
    expect(strokes[0].points.last.atMs, 300);
  });

  test(
    'the player sends simultaneous events in one write, on schedule',
    () async {
      final writes = <Uint8List>[];
      final events = [
        const McpTouchEvent(0, 0, McpTouchEvent.down, 1, 1),
        const McpTouchEvent(0, 1, McpTouchEvent.down, 2, 2),
        const McpTouchEvent(60, 0, McpTouchEvent.up, 1, 1),
        const McpTouchEvent(60, 1, McpTouchEvent.up, 2, 2),
      ];
      final r = await McpTouchPlayer.play(
        events,
        width: 100,
        height: 100,
        send: writes.add,
      );
      expect(writes.map((w) => w.length), [64, 64]); // two 32-byte touches
      expect(r.durationMs, greaterThanOrEqualTo(60));
      expect(writes.first[0], 2); // INJECT_TOUCH_EVENT
    },
  );

  group('executor', () {
    late _MockAdb adb;
    setUp(() {
      adb = _MockAdb();
      when(() => adb.getDisplaySize(any()))
          .thenAnswer((_) async => const Point(1000, 2000));
    });

    test('strokes go to the session sink', () async {
      final writes = <Uint8List>[];
      final executor = McpGestureToolExecutor(
        adb,
        openSession: (_) async => (send: writes.add, flush: () async {}),
      );
      final r = await executor.execute('android_touch_strokes', 'S', {
        'strokes': _joystickAndTap,
      });
      expect(r.isError, isFalse, reason: r.content.first.text);
      expect(r.content.first.text, contains('Played 2 stroke(s)'));
      expect(writes, isNotEmpty);
    });

    test('pinch falls back to one finger when scrcpy is unavailable', () async {
      when(
        () => adb.pinchGesture(
          any(),
          scale: any(named: 'scale'),
          centerX: any(named: 'centerX'),
          centerY: any(named: 'centerY'),
          durationMs: any(named: 'durationMs'),
        ),
      ).thenAnswer((_) async => true);
      final executor = McpGestureToolExecutor(
        adb,
        openSession: (_) async =>
            throw const McpUnsupportedOnDeviceException('no jar'),
      );
      final r = await executor.execute('android_pinch_gesture', 'S', {
        'scale': 1.5,
      });
      expect(r.content.first.text, startsWith('One-finger approximation'));
      expect(r.content.first.text, contains('no jar'));
    });
  });

  // The server rejects unknown keys (see scrcpy_server_command_test.dart).
  test('the touch session only uses options the bundled server knows', () {
    final archive = ZipDecoder().decodeBytes(
      File(ScrcpyServerConstants.assetKey).readAsBytesSync(),
    );
    final dex = latin1.decode(archive.findFile('classes.dex')!.readBytes()!);
    final args = McpScrcpyTouchSession.serverArguments('S', '1a2b3c4d');
    for (final arg in args.skip(8)) {
      expect(dex.contains(arg.split('=').first), isTrue, reason: arg);
    }
    expect(args, contains('video=false'));
    expect(args, isNot(contains('scid=00000000')));
  });
}
