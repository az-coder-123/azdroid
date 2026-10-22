import 'dart:io';
import 'dart:typed_data';

import 'package:desk_droid/features/mcp/data/services/mcp_adb_client.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_fast_input.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_unsupported_exception.dart';
import 'package:desk_droid/features/mcp/data/utils/mcp_point.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAdb extends Mock implements McpAdbClient {}

void main() {
  setUpAll(() => registerFallbackValue(McpPoint.pixels(0, 0)));
  const serial = 'M13';
  late _MockAdb adb;
  late List<String> commands;
  late List<Uint8List> writes;
  late int opens;

  /// (action, pointerId, x, y) of each 32-byte touch message written.
  List<(int, int, int, int)> touches() => [
    for (final w in writes)
      for (var o = 0; o < w.length; o += 32)
        () {
          final d = ByteData.sublistView(w, o, o + 32);
          return (d.getUint8(1), d.getInt64(2), d.getInt32(10), d.getInt32(14));
        }(),
  ];

  setUp(() {
    adb = _MockAdb();
    commands = [];
    writes = [];
    opens = 0;
    McpFastInput.reset();
    McpFastInput.opener = (_, _) async {
      opens++;
      return (send: writes.add, flush: () async {});
    };
    when(() => adb.getDisplaySize(serial))
        .thenAnswer((_) async => const Point(1000, 2000));
    when(() => adb.run(any())).thenAnswer((i) async {
      commands.add((i.positionalArguments.first as List<String>).join(' '));
      return ProcessResult(1, 0, '', '');
    });
  });

  test('a tap goes through the session, not input tap', () async {
    expect(
      await McpAdbInputOps.tap(adb, serial, McpPoint.pixels(10, 20)),
      isTrue,
    );
    expect(touches(), [(0, 0, 10, 20), (1, 0, 10, 20)]);
    expect(commands.where((c) => c.contains('input')), isEmpty);
  });

  test('a double tap is two presses on the same spot', () async {
    await McpAdbInputOps.doubleTap(
      adb,
      serial,
      McpPoint.pixels(5, 5),
      intervalMs: 100,
    );
    expect(touches().map((t) => t.$1), [0, 1, 0, 1]);
  });

  test('a swipe moves the finger in between', () async {
    await McpAdbInputOps.swipe(
      adb,
      serial,
      McpPoint.pixels(0, 0),
      McpPoint.pixels(0, 400),
      80,
    );
    final t = touches();
    expect(t.first, (0, 0, 0, 0));
    expect(t.last, (1, 0, 0, 400));
    expect(t.where((e) => e.$1 == 2).length, greaterThan(5));
  });

  test('without a session: adb, and no retry for a minute', () async {
    McpFastInput.opener = (_, _) async {
      opens++;
      throw const McpUnsupportedOnDeviceException('no jar');
    };
    await McpAdbInputOps.tap(adb, serial, McpPoint.pixels(1, 2));
    await McpAdbInputOps.tap(adb, serial, McpPoint.pixels(1, 2));
    expect(commands.where((c) => c.endsWith('input tap 1 2')), hasLength(2));
    expect(opens, 1);
  });

  test('a key is a scrcpy key down and up, not input keyevent', () async {
    expect(await McpAdbTextOps.pressKey(adb, serial, 4), isTrue);
    final bytes = writes.expand((w) => w).toList();
    // Two 14-byte INJECT_KEYCODE messages: type 0, action down then up.
    expect(bytes, hasLength(28));
    expect([bytes[0], bytes[1], bytes[14], bytes[15]], [0, 0, 0, 1]);
    expect(ByteData.sublistView(Uint8List.fromList(bytes)).getInt32(2), 4);
    expect(commands.where((c) => c.contains('keyevent')), isEmpty);
  });

  test(
    'a batch with the session injects each step, pinch with two fingers',
    () async {
      when(() => adb.tap(serial, any())).thenAnswer(
        (i) => McpAdbInputOps.tap(
          adb,
          serial,
          i.positionalArguments[1] as McpPoint,
        ),
      );
      final results = await McpAdbBatchOps.batchActions(adb, serial, [
        {'action': 'tap', 'x': 0.5, 'y': 0.5},
        {'action': 'pinch', 'scale': 2},
      ]);
      expect(
        results.every((r) => r['success'] == true),
        isTrue,
        reason: '$results',
      );
      expect(commands.where((c) => c.contains('input')), isEmpty);
      // Pinch: two pointer ids down at once.
      final downs = touches().where((t) => t.$1 == 0).map((t) => t.$2).toSet();
      expect(downs, containsAll([0, 1]));
    },
  );

  test('a batch without the session stays one compound adb script', () async {
    McpFastInput.opener = (_, _) async =>
        throw const McpUnsupportedOnDeviceException('no jar');
    await McpAdbBatchOps.batchActions(adb, serial, [
      {'action': 'tap', 'x': 10, 'y': 10},
      {'action': 'key', 'keyCode': 4},
    ]);
    final input = commands.where((c) => c.contains('input')).toList();
    expect(input, hasLength(1));
    expect(input.single, contains('input tap 10 10'));
    expect(input.single, contains('input keyevent 4'));
  });

  test('a key right after a tap waits for the minimum gap', () async {
    final watch = Stopwatch()..start();
    await McpAdbInputOps.tap(adb, serial, McpPoint.pixels(1, 1));
    final afterTap = watch.elapsedMilliseconds;
    await McpAdbTextOps.pressKey(adb, serial, 4);
    expect(
      watch.elapsedMilliseconds - afterTap,
      greaterThanOrEqualTo(McpFastInput.minGap.inMilliseconds - 5),
    );
  });
}
