import 'package:flutter/material.dart';
import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/core/theme/app_typography.dart';

/// Context banner showing the host Mac Wi-Fi IP address to ensure subnet parity with phone.
class PairingHostIpBanner extends StatelessWidget {
  const PairingHostIpBanner({super.key, required this.hostMacIp});

  final String? hostMacIp;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.wifi_rounded,
            size: 16,
            color: AppColors.statusSuccess,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hostMacIp != null
                  ? 'Mac Wi-Fi IP: $hostMacIp'
                  : 'Detecting Mac Wi-Fi IP...',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Flexible(
            child: Text(
              'Must match Phone Wi-Fi',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
