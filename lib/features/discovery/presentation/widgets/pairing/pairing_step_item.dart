import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// Numbered instructional step item used in pairing instructions.
class PairingStepItem extends StatelessWidget {
  const PairingStepItem({super.key, required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number. ',
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.accent,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
