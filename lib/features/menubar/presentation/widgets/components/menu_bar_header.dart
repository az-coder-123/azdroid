import 'package:flutter/material.dart';
import 'package:desk_droid/core/theme/app_colors.dart';

/// Top header for the menu bar companion popover, rendering app branding and live status pill.
class MenuBarHeader extends StatelessWidget {
  const MenuBarHeader({super.key, required this.isMirroring});

  final bool isMirroring;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.desktop_mac_rounded,
                  color: AppColors.accent,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Flexible(
                child: Text(
                  'DeskDroid Companion',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isMirroring
                ? AppColors.statusSuccess.withValues(alpha: 0.15)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isMirroring
                  ? AppColors.statusSuccess.withValues(alpha: 0.4)
                  : AppColors.borderSubtle,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 3,
                backgroundColor: isMirroring
                    ? AppColors.statusSuccess
                    : AppColors.textTertiary,
              ),
              const SizedBox(width: 5),
              Text(
                isMirroring ? 'Mirroring' : 'Idle',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isMirroring
                      ? AppColors.statusSuccess
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
