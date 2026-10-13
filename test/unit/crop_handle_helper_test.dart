import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wifi_desk/features/productivity/presentation/utils/crop_handle_helper.dart';

void main() {
  const testRect = Rect.fromLTWH(100, 100, 200, 200);
  const bounds = Size(500, 500);

  group('CropHandleHelper.hitTest', () {
    test('identifies corner handles within hit radius', () {
      expect(
        CropHandleHelper.hitTest(const Offset(100, 100), testRect),
        CropHandle.topLeft,
      );
      expect(
        CropHandleHelper.hitTest(const Offset(300, 100), testRect),
        CropHandle.topRight,
      );
      expect(
        CropHandleHelper.hitTest(const Offset(100, 300), testRect),
        CropHandle.bottomLeft,
      );
      expect(
        CropHandleHelper.hitTest(const Offset(300, 300), testRect),
        CropHandle.bottomRight,
      );
    });

    test('identifies edge midpoint handles', () {
      expect(
        CropHandleHelper.hitTest(const Offset(200, 100), testRect),
        CropHandle.top,
      );
      expect(
        CropHandleHelper.hitTest(const Offset(200, 300), testRect),
        CropHandle.bottom,
      );
      expect(
        CropHandleHelper.hitTest(const Offset(100, 200), testRect),
        CropHandle.left,
      );
      expect(
        CropHandleHelper.hitTest(const Offset(300, 200), testRect),
        CropHandle.right,
      );
    });

    test('identifies move when clicking inside body', () {
      expect(
        CropHandleHelper.hitTest(const Offset(200, 200), testRect),
        CropHandle.move,
      );
    });

    test('identifies none when clicking far outside', () {
      expect(
        CropHandleHelper.hitTest(const Offset(10, 10), testRect),
        CropHandle.none,
      );
    });
  });

  group('CropHandleHelper.getCursor', () {
    test('maps handles to appropriate system mouse cursors', () {
      expect(
        CropHandleHelper.getCursor(CropHandle.topLeft),
        SystemMouseCursors.resizeUpLeftDownRight,
      );
      expect(
        CropHandleHelper.getCursor(CropHandle.topRight),
        SystemMouseCursors.resizeUpRightDownLeft,
      );
      expect(
        CropHandleHelper.getCursor(CropHandle.top),
        SystemMouseCursors.resizeUpDown,
      );
      expect(
        CropHandleHelper.getCursor(CropHandle.left),
        SystemMouseCursors.resizeLeftRight,
      );
      expect(
        CropHandleHelper.getCursor(CropHandle.move),
        SystemMouseCursors.move,
      );
      expect(
        CropHandleHelper.getCursor(CropHandle.none),
        SystemMouseCursors.precise,
      );
    });
  });

  group('CropHandleHelper.transformRect', () {
    test('translates rect when handle is move and bounds correctly', () {
      final shifted = CropHandleHelper.transformRect(
        currentRect: testRect,
        handle: CropHandle.move,
        delta: const Offset(50, 50),
        bounds: bounds,
      );

      expect(shifted, const Rect.fromLTWH(150, 150, 200, 200));
    });

    test('clamps translation at parent boundary', () {
      final shifted = CropHandleHelper.transformRect(
        currentRect: testRect,
        handle: CropHandle.move,
        delta: const Offset(-200, -200),
        bounds: bounds,
      );

      expect(shifted.left, 0.0);
      expect(shifted.top, 0.0);
      expect(shifted.width, 200.0);
      expect(shifted.height, 200.0);
    });

    test('resizes from bottomRight expanding width and height', () {
      final resized = CropHandleHelper.transformRect(
        currentRect: testRect,
        handle: CropHandle.bottomRight,
        delta: const Offset(40, 60),
        bounds: bounds,
      );

      expect(resized.left, 100.0);
      expect(resized.top, 100.0);
      expect(resized.width, 240.0);
      expect(resized.height, 260.0);
    });

    test('enforces minimum size when resizing topLeft inwards', () {
      final resized = CropHandleHelper.transformRect(
        currentRect: testRect,
        handle: CropHandle.topLeft,
        delta: const Offset(300, 300),
        bounds: bounds,
        minSize: 20.0,
      );

      expect(resized.right, 300.0);
      expect(resized.bottom, 300.0);
      expect(resized.width, 20.0);
      expect(resized.height, 20.0);
    });
  });
}
