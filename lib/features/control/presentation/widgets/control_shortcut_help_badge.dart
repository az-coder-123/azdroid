import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Subtle HUD badge showing mouse and keyboard shortcuts in the mirroring viewport.
class ControlShortcutHelpBadge extends StatelessWidget {
  const ControlShortcutHelpBadge({super.key, required this.onTapTextInject});

  final VoidCallback onTapTextInject;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.mouse_outlined,
            size: 13,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 5),
          const Text(
            'R-Click: Back  •  M-Click: Home',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
              fontFamily: 'SF Pro Text',
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onTapTextInject,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.keyboard_alt_outlined,
                    size: 11,
                    color: AppColors.accentLight,
                  ),
                  SizedBox(width: 3),
                  Text(
                    '⌘K Text',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
