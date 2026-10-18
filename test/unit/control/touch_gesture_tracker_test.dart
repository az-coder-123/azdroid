import 'dart:math' as math;

import 'package:desk_droid/core/constants/control_constants.dart';
import 'package:desk_droid/features/control/domain/entities/touch_stream.dart';
import 'package:desk_droid/features/control/presentation/utils/touch_gesture_tracker.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const viewport = Size(400, 800);
  late List<(TouchStreamPhase, List<NormalizedPoint>)> events;
  late TouchGestureTracker tracker;

  setUp(() {
    events = [];
    tracker = TouchGestureTracker(
      (phase, points) => events.add((phase, points)),
    );
  });

  Matcher near(double x, double y) => isA<NormalizedPoint>()
      .having((p) => p.x, 'x', closeTo(x, 1e-9))
      .having((p) => p.y, 'y', closeTo(y, 1e-9));

  group('trackpad', () {
    test('a resting hand sends nothing', () {
      tracker
        ..panZoomStart(const Offset(200, 400), viewport)
        ..panZoomUpdate(pan: const Offset(1, 1), scale: 1.01, rotation: 0.01)
        ..panZoomEnd();

      expect(events, isEmpty);
      expect(tracker.isActive, isFalse);
    });

    test('a pan becomes one live finger that follows it', () {
      tracker
        ..panZoomStart(const Offset(200, 400), viewport)
        ..panZoomUpdate(pan: const Offset(0, -40), scale: 1, rotation: 0)
        ..panZoomUpdate(pan: const Offset(0, -80), scale: 1, rotation: 0)
        ..panZoomEnd();

      expect(events.map((e) => e.$1), [
        TouchStreamPhase.start,
        TouchStreamPhase.move,
        TouchStreamPhase.move,
        TouchStreamPhase.end,
      ]);
      expect(events.first.$2.single, near(0.5, 0.5));
      expect(events[2].$2.single, near(0.5, 0.4));
      expect(events.last.$2.single, near(0.5, 0.4)); // Lifts where it is.
    });

    test('a scale change becomes two fingers apart by span × scale', () {
      tracker
        ..panZoomStart(const Offset(200, 400), viewport)
        ..panZoomUpdate(pan: Offset.zero, scale: 1.5, rotation: 0);

      final (phase, fingers) = events.single;
      expect(phase, TouchStreamPhase.start);
      // Span = 400 × fraction × 1.5, split around x = 200.
      const half = 400 * ControlConstants.pinchInitialSpanFraction * 1.5 / 2;
      expect(fingers, [
        near((200 + half) / 400, 0.5),
        near((200 - half) / 400, 0.5),
      ]);
    });

    test('rotation turns the finger pair; it stays a pinch to the end', () {
      tracker
        ..panZoomStart(const Offset(200, 400), viewport)
        ..panZoomUpdate(pan: Offset.zero, scale: 1, rotation: 0.5)
        ..panZoomUpdate(pan: Offset.zero, scale: 1, rotation: math.pi / 2)
        ..panZoomEnd();

      final quarterTurn = events[1].$2;
      // At 90°, the fingers sit above and below the center.
      expect(quarterTurn[0].x, closeTo(0.5, 1e-9));
      expect(quarterTurn[1].x, closeTo(0.5, 1e-9));
      expect(quarterTurn[0].y, greaterThan(0.5));
      expect(events.last.$1, TouchStreamPhase.end);
      expect(events.last.$2, hasLength(2));
    });

    test('fingers are clamped inside the frame', () {
      tracker
        ..panZoomStart(const Offset(5, 5), viewport)
        ..panZoomUpdate(pan: Offset.zero, scale: 3, rotation: 0);

      for (final finger in events.single.$2) {
        expect(finger.x, inInclusiveRange(0, 1));
        expect(finger.y, inInclusiveRange(0, 1));
      }
    });
  });

  group('Alt-drag', () {
    test('the second finger mirrors the mouse through the center', () {
      tracker
        ..mirroredStart(const Offset(100, 200), viewport)
        ..mirroredMove(const Offset(50, 100))
        ..mirroredEnd();

      expect(events.first.$2, [near(0.25, 0.25), near(0.75, 0.75)]);
      expect(events[1].$2, [near(0.125, 0.125), near(0.875, 0.875)]);
      expect(events.last.$1, TouchStreamPhase.end);
      expect(tracker.isMirroring, isFalse);
    });

    test('moves without an Alt-drag are ignored', () {
      tracker.mirroredMove(const Offset(10, 10));
      expect(events, isEmpty);
    });
  });

  test('a new gesture first lifts the fingers of the previous one', () {
    tracker
      ..mirroredStart(const Offset(100, 200), viewport)
      ..panZoomStart(const Offset(200, 400), viewport);

    expect(events.map((e) => e.$1), [
      TouchStreamPhase.start,
      TouchStreamPhase.end,
    ]);
  });
}
