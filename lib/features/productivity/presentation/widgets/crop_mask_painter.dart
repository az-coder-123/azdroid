import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Custom painter rendering a dimmed background mask with a transparent cutout
/// for the selected crop region, accentuated with crisp borders, reticles, and resize handles.
class CropMaskPainter extends CustomPainter {
  const CropMaskPainter({
    required this.selectionRect,
    required this.maskColor,
    required this.borderColor,
    this.showHandles = false,
  });

  final Rect? selectionRect;
  final Color maskColor;
  final Color borderColor;
  final bool showHandles;

  @override
  void paint(Canvas canvas, Size size) {
    final fullRect = Offset.zero & size;
    final bgPaint = Paint()..color = maskColor;

    if (selectionRect == null || selectionRect!.isEmpty) {
      canvas.drawRect(fullRect, bgPaint);
      return;
    }

    final sel = selectionRect!;

    // Cutout path via even-odd fill rule
    final path = Path()
      ..addRect(fullRect)
      ..addRect(sel)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, bgPaint);

    // Selected region perimeter border
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(sel, borderPaint);

    if (showHandles) {
      _paintHandleKnobs(canvas, sel);
    } else {
      _paintCornerReticles(canvas, sel);
    }
  }

  void _paintCornerReticles(Canvas canvas, Rect sel) {
    final cornerLength = math.min(12.0, math.min(sel.width, sel.height) / 3);
    if (cornerLength <= 4) return;

    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // Top-Left
    canvas.drawLine(sel.topLeft, sel.topLeft + Offset(cornerLength, 0), paint);
    canvas.drawLine(sel.topLeft, sel.topLeft + Offset(0, cornerLength), paint);
    // Top-Right
    canvas.drawLine(
      sel.topRight,
      sel.topRight + Offset(-cornerLength, 0),
      paint,
    );
    canvas.drawLine(
      sel.topRight,
      sel.topRight + Offset(0, cornerLength),
      paint,
    );
    // Bottom-Left
    canvas.drawLine(
      sel.bottomLeft,
      sel.bottomLeft + Offset(cornerLength, 0),
      paint,
    );
    canvas.drawLine(
      sel.bottomLeft,
      sel.bottomLeft + Offset(0, -cornerLength),
      paint,
    );
    // Bottom-Right
    canvas.drawLine(
      sel.bottomRight,
      sel.bottomRight + Offset(-cornerLength, 0),
      paint,
    );
    canvas.drawLine(
      sel.bottomRight,
      sel.bottomRight + Offset(0, -cornerLength),
      paint,
    );
  }

  void _paintHandleKnobs(Canvas canvas, Rect sel) {
    final fillPaint = Paint()..color = Colors.white;
    final strokePaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    final shadowPaint = Paint()..color = Colors.black38;
    const radius = 5.0;

    final handles = [
      sel.topLeft,
      sel.topRight,
      sel.bottomLeft,
      sel.bottomRight,
      Offset(sel.center.dx, sel.top),
      Offset(sel.center.dx, sel.bottom),
      Offset(sel.left, sel.center.dy),
      Offset(sel.right, sel.center.dy),
    ];

    for (final pt in handles) {
      canvas.drawCircle(pt + const Offset(0, 1), radius + 1.0, shadowPaint);
      canvas.drawCircle(pt, radius, fillPaint);
      canvas.drawCircle(pt, radius, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CropMaskPainter oldDelegate) {
    return oldDelegate.selectionRect != selectionRect ||
        oldDelegate.maskColor != maskColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.showHandles != showHandles;
  }
}
