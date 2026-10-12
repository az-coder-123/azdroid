import 'package:flutter/material.dart';
import 'package:wifi_desk/core/theme/app_colors.dart';
import 'package:wifi_desk/core/theme/app_typography.dart';

/// Top bar header for the wireless pairing dialog.
class PairingDialogHeader extends StatelessWidget {
  const PairingDialogHeader({
    super.key,
    required this.isSubmitting,
    required this.onClose,
  });

  final bool isSubmitting;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.phonelink_lock_rounded,
            color: AppColors.accent,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pair Wireless Device', style: AppTypography.title),
              const SizedBox(height: 2),
              Text(
                'Android 11+ Wireless Debugging Pairing',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close_rounded, size: 20),
          onPressed: isSubmitting ? null : onClose,
        ),
      ],
    );
  }
}
