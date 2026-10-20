import 'dart:io';

import 'package:desk_droid/features/mcp/data/services/mcp_adb_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockMcpAdbClient extends Mock implements McpAdbClient {}

void main() {
  late MockMcpAdbClient mockAdb;

  setUp(() {
    mockAdb = MockMcpAdbClient();
    when(() => mockAdb.run(any())).thenAnswer(
      (_) async => ProcessResult(123, 0, 'Physical size: 1080x2400', ''),
    );
    when(() => mockAdb.getDisplaySize('dev1'))
        .thenAnswer((_) async => const Point(1080, 2400));
  });

  group('McpAdbBatchOps Tests', () {
    test('executes pinch and rotate macro actions via McpAdbClient', () async {
      when(
        () => mockAdb.pinchGesture(
          'dev1',
          scale: 1.8,
          centerX: any(named: 'centerX'),
          centerY: any(named: 'centerY'),
          durationMs: any(named: 'durationMs'),
        ),
      ).thenAnswer((_) async => true);

      when(
        () => mockAdb.rotateGesture(
          'dev1',
          angleDegrees: 45.0,
          centerX: any(named: 'centerX'),
          centerY: any(named: 'centerY'),
          radius: any(named: 'radius'),
          durationMs: any(named: 'durationMs'),
        ),
      ).thenAnswer((_) async => true);

      when(
        () => mockAdb.doubleTap(
          'dev1',
          any(),
          any(),
          intervalMs: any(named: 'intervalMs'),
        ),
      ).thenAnswer((_) async => true);

      final results = await McpAdbBatchOps.batchActions(mockAdb, 'dev1', [
        {'action': 'double_tap', 'x': 540, 'y': 1200, 'intervalMs': 100},
        {
          'action': 'pinch',
          'scale': 1.8,
          'centerX': 0.5,
          'centerY': 0.5,
          'durationMs': 350,
        },
        {
          'action': 'rotate',
          'angleDegrees': 45.0,
          'centerX': 0.5,
          'centerY': 0.5,
          'radius': 180,
          'durationMs': 400,
        },
      ]);

      expect(results.length, equals(3));
      expect(results[0]['action'], equals('double_tap'));
      expect(results[0]['success'], isTrue);
      expect(results[1]['action'], equals('pinch'));
      expect(results[1]['success'], isTrue);
      expect(results[2]['action'], equals('rotate'));
      expect(results[2]['success'], isTrue);

      verify(() => mockAdb.doubleTap('dev1', 540.0, 1200.0, intervalMs: 100))
          .called(1);
      verify(
        () => mockAdb.pinchGesture(
          'dev1',
          scale: 1.8,
          centerX: 0.5,
          centerY: 0.5,
          durationMs: 350,
        ),
      ).called(1);
      verify(
        () => mockAdb.rotateGesture(
          'dev1',
          angleDegrees: 45.0,
          centerX: 0.5,
          centerY: 0.5,
          radius: 180.0,
          durationMs: 400,
        ),
      ).called(1);
    });

    test(
      'compiles shell actions and executes in a single compound ADB shell call',
      () async {
        when(() => mockAdb.run(any())).thenAnswer((invocation) async {
          final args = invocation.positionalArguments[0] as List<String>;
          if (args.contains('shell')) {
            return ProcessResult(
              123,
              0,
              'DD_STEP:0:OK\nDD_STEP:1:OK\nDD_STEP:2:OK',
              '',
            );
          }
          return ProcessResult(123, 0, '', '');
        });

        final results = await McpAdbBatchOps.batchActions(mockAdb, 'dev1', [
          {'action': 'tap', 'x': 200, 'y': 400},
          {'action': 'type', 'text': 'hello'},
          {'action': 'scroll', 'direction': 'down', 'distance': 0.5},
        ]);

        expect(results.length, equals(3));
        expect(results.every((r) => r['success'] == true), isTrue);
      },
    );

    test('McpAdbBatchCompiler compiles scroll and fling correctly', () {
      const size = Point(1080, 2400);
      final scrollDown = McpAdbBatchCompiler.compile({
        'action': 'scroll',
        'direction': 'down',
        'distance': 0.6,
      }, size);
      expect(scrollDown, contains('input swipe 540 1920 540 480 250'));

      final flingUp = McpAdbBatchCompiler.compile({
        'action': 'fling',
        'direction': 'up',
        'distance': 0.5,
      }, size);
      expect(flingUp, contains('input swipe 540 600 540 1800 80'));
    });
  });
}
