import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Custom painter rendering a dimmed background mask with a transparent cutout
/// for the selected crop region, accentuated with crisp borders and corner reticles.
class CropMaskPainter extends CustomPainter {
  const CropMaskPainter({
    required this.selectionRect,
    required this.maskColor,
    required this.borderColor,
  });

  final Rect? selectionRect;
  final Color maskColor;
  final Color borderColor;

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

    // Corner reticles for Apple macOS screenshot aesthetic
    final cornerLength = math.min(12.0, math.min(sel.width, sel.height) / 3);
    if (cornerLength > 4) {
      final cornerPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;

      // Top-Left corner
      canvas.drawLine(
        sel.topLeft,
        sel.topLeft + Offset(cornerLength, 0),
        cornerPaint,
      );
      canvas.drawLine(
        sel.topLeft,
        sel.topLeft + Offset(0, cornerLength),
        cornerPaint,
      );
      // Top-Right corner
      canvas.drawLine(
        sel.topRight,
        sel.topRight + Offset(-cornerLength, 0),
        cornerPaint,
      );
      canvas.drawLine(
        sel.topRight,
        sel.topRight + Offset(0, cornerLength),
        cornerPaint,
      );
      // Bottom-Left corner
      canvas.drawLine(
        sel.bottomLeft,
        sel.bottomLeft + Offset(cornerLength, 0),
        cornerPaint,
      );
      canvas.drawLine(
        sel.bottomLeft,
        sel.bottomLeft + Offset(0, -cornerLength),
        cornerPaint,
      );
      // Bottom-Right corner
      canvas.drawLine(
        sel.bottomRight,
        sel.bottomRight + Offset(-cornerLength, 0),
        cornerPaint,
      );
      canvas.drawLine(
        sel.bottomRight,
        sel.bottomRight + Offset(0, -cornerLength),
        cornerPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CropMaskPainter oldDelegate) {
    return oldDelegate.selectionRect != selectionRect ||
        oldDelegate.maskColor != maskColor ||
        oldDelegate.borderColor != borderColor;
  }
}
