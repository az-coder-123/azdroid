import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// Card container with a colored pill badge, title, and body children.
class GuideCard extends StatelessWidget {
  const GuideCard({
    super.key,
    required this.badgeText,
    required this.badgeColor,
    required this.title,
    required this.children,
  });

  final String badgeText;
  final Color badgeColor;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(title, style: AppTypography.title.copyWith(fontSize: 15)),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}
