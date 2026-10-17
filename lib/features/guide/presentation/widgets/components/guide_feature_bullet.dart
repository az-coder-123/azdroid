import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// Single bullet feature row with colored icon and text.
class GuideFeatureBullet extends StatelessWidget {
  const GuideFeatureBullet({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.statusSuccess),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppTypography.body)),
        ],
      ),
    );
  }
}
