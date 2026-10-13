import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:wifi_desk/core/theme/app_colors.dart';

/// Floating badge displaying the active width and height dimensions of the selection.
class CropDimensionBadge extends StatelessWidget {
  const CropDimensionBadge({
    super.key,
    required this.selectionRect,
    required this.viewportHeight,
  });

  final Rect selectionRect;
  final double viewportHeight;

  @override
  Widget build(BuildContext context) {
    final topPos = (selectionRect.bottom + 8 < viewportHeight - 30)
        ? selectionRect.bottom + 8.0
        : (math.max(8.0, selectionRect.top - 28.0)).toDouble();

    return Positioned(
      left: selectionRect.left + (selectionRect.width / 2) - 45,
      top: topPos,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.7)),
        ),
        child: Text(
          '${selectionRect.width.toInt()} × ${selectionRect.height.toInt()} px',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
