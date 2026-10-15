import 'package:flutter/material.dart';
import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/core/theme/app_typography.dart';
import 'package:desk_droid/features/discovery/presentation/cubit/pairing_state.dart';

/// Feedback banner rendering active error or pairing success message.
class PairingStatusBanner extends StatelessWidget {
  const PairingStatusBanner({super.key, required this.state});

  final PairingState state;

  @override
  Widget build(BuildContext context) {
    if (state is PairingFailure) {
      final error = (state as PairingFailure).error;
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.statusError.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.statusError.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.statusError,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                error,
                style: AppTypography.caption.copyWith(
                  color: AppColors.statusError,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (state is PairingSuccess) {
      final message = (state as PairingSuccess).message;
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.statusSuccess.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.statusSuccess.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_outline_rounded,
              color: AppColors.statusSuccess,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: AppTypography.caption.copyWith(
                  color: AppColors.statusSuccess,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
