import 'package:flutter/material.dart';

/// Interactive handles for resizing or translating a crop selection region.
enum CropHandle {
  none,
  move,
  topLeft,
  top,
  topRight,
  right,
  bottomRight,
  bottom,
  bottomLeft,
  left,
}

/// Helper methods for hit testing, mouse cursors, and rectangular transform geometry.
class CropHandleHelper {
  const CropHandleHelper._();

  /// Hit-tests a local point against the selection handles or bounding body.
  static CropHandle hitTest(
    Offset point,
    Rect rect, {
    double hitRadius = 14.0,
  }) {
    // 1. Check corner handles
    if ((point - rect.topLeft).distance <= hitRadius) return CropHandle.topLeft;
    if ((point - rect.topRight).distance <= hitRadius) {
      return CropHandle.topRight;
    }
    if ((point - rect.bottomLeft).distance <= hitRadius) {
      return CropHandle.bottomLeft;
    }
    if ((point - rect.bottomRight).distance <= hitRadius) {
      return CropHandle.bottomRight;
    }

    // 2. Check edge midpoints
    final midTop = Offset(rect.center.dx, rect.top);
    if ((point - midTop).distance <= hitRadius) return CropHandle.top;

    final midBottom = Offset(rect.center.dx, rect.bottom);
    if ((point - midBottom).distance <= hitRadius) return CropHandle.bottom;

    final midLeft = Offset(rect.left, rect.center.dy);
    if ((point - midLeft).distance <= hitRadius) return CropHandle.left;

    final midRight = Offset(rect.right, rect.center.dy);
    if ((point - midRight).distance <= hitRadius) return CropHandle.right;

    // 3. Check inside body for translation/moving
    if (rect.contains(point)) return CropHandle.move;

    return CropHandle.none;
  }

  /// Maps an active handle to the idiomatic desktop mouse cursor.
  static MouseCursor getCursor(CropHandle handle) {
    switch (handle) {
      case CropHandle.topLeft:
      case CropHandle.bottomRight:
        return SystemMouseCursors.resizeUpLeftDownRight;
      case CropHandle.topRight:
      case CropHandle.bottomLeft:
        return SystemMouseCursors.resizeUpRightDownLeft;
      case CropHandle.top:
      case CropHandle.bottom:
        return SystemMouseCursors.resizeUpDown;
      case CropHandle.left:
      case CropHandle.right:
        return SystemMouseCursors.resizeLeftRight;
      case CropHandle.move:
        return SystemMouseCursors.move;
      case CropHandle.none:
        return SystemMouseCursors.precise;
    }
  }

  /// Transforms the given [rect] based on the active [handle] and translation [delta].
  static Rect transformRect({
    required Rect currentRect,
    required CropHandle handle,
    required Offset delta,
    required Size bounds,
    double minSize = 16.0,
  }) {
    if (handle == CropHandle.move) {
      var dx = delta.dx;
      var dy = delta.dy;

      if (currentRect.left + dx < 0.0) dx = -currentRect.left;
      if (currentRect.right + dx > bounds.width) {
        dx = bounds.width - currentRect.right;
      }
      if (currentRect.top + dy < 0.0) dy = -currentRect.top;
      if (currentRect.bottom + dy > bounds.height) {
        dy = bounds.height - currentRect.bottom;
      }

      return currentRect.shift(Offset(dx, dy));
    }

    var left = currentRect.left;
    var top = currentRect.top;
    var right = currentRect.right;
    var bottom = currentRect.bottom;

    if (handle == CropHandle.topLeft ||
        handle == CropHandle.left ||
        handle == CropHandle.bottomLeft) {
      left = (left + delta.dx).clamp(0.0, right - minSize);
    }
    if (handle == CropHandle.topRight ||
        handle == CropHandle.right ||
        handle == CropHandle.bottomRight) {
      right = (right + delta.dx).clamp(left + minSize, bounds.width);
    }
    if (handle == CropHandle.topLeft ||
        handle == CropHandle.top ||
        handle == CropHandle.topRight) {
      top = (top + delta.dy).clamp(0.0, bottom - minSize);
    }
    if (handle == CropHandle.bottomLeft ||
        handle == CropHandle.bottom ||
        handle == CropHandle.bottomRight) {
      bottom = (bottom + delta.dy).clamp(top + minSize, bounds.height);
    }

    return Rect.fromLTRB(left, top, right, bottom);
  }
}
