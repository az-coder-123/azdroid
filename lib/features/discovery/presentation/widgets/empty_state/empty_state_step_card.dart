import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// Card displaying an individual onboarding step in the Discovery empty state launchpad.
class EmptyStateStepCard extends StatelessWidget {
  const EmptyStateStepCard({
    super.key,
    required this.stepNumber,
    required this.icon,
    required this.title,
    required this.description,
    this.badgeText,
    this.badgeColor,
    this.badgeIcon,
  });

  final int stepNumber;
  final IconData icon;
  final String title;
  final String description;
  final String? badgeText;
  final Color? badgeColor;
  final IconData? badgeIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Step number pill
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$stepNumber',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Icon(icon, size: 20, color: AppColors.textSecondary),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          if (badgeText != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (badgeColor ?? AppColors.statusSuccess).withValues(
                  alpha: 0.12,
                ),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: (badgeColor ?? AppColors.statusSuccess).withValues(
                    alpha: 0.3,
                  ),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (badgeIcon != null) ...[
                    Icon(
                      badgeIcon,
                      size: 11,
                      color: badgeColor ?? AppColors.statusSuccess,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Flexible(
                    child: Text(
                      badgeText!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: badgeColor ?? AppColors.statusSuccess,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
