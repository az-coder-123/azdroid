import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:desk_droid/core/theme/app_colors.dart';

/// Floating instruction pill at the top of the crop selection overlay.
class CropInstructionPill extends StatelessWidget {
  const CropInstructionPill({
    super.key,
    required this.hasSelection,
    required this.maxWidth,
    required this.onCancel,
  });

  final bool hasSelection;
  final double maxWidth;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final text = hasSelection
        ? 'Drag handles to adjust • Drag inside to move • Esc to cancel'
        : 'Drag to select area • Esc to cancel';

    return Positioned(
      top: 14,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: math.max(0.0, maxWidth - 24)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.crop_rounded, size: 15, color: AppColors.accent),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onCancel,
                child: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
