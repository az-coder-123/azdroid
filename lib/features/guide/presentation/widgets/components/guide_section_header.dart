import 'package:flutter/material.dart';
import 'package:wifi_desk/core/theme/app_colors.dart';
import 'package:wifi_desk/core/theme/app_typography.dart';

/// Standardized section title, subtitle, and divider for user guide pages.
class GuideSectionHeader extends StatelessWidget {
  const GuideSectionHeader({
    super.key,
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.title.copyWith(fontSize: 17)),
        const SizedBox(height: 4),
        Text(description, style: AppTypography.subtitle.copyWith(fontSize: 13)),
        const SizedBox(height: 8),
        const Divider(color: AppColors.borderSubtle),
      ],
    );
  }
}
