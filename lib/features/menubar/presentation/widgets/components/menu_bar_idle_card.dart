import 'package:flutter/material.dart';
import 'package:desk_droid/core/theme/app_colors.dart';

/// Card displayed when no active mirroring stream is running.
class MenuBarIdleCard extends StatelessWidget {
  const MenuBarIdleCard({super.key, required this.discoveredDeviceCount});

  final int discoveredDeviceCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.wifi_tethering_rounded,
            size: 16,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              discoveredDeviceCount > 0
                  ? '$discoveredDeviceCount device(s) ready on Wi-Fi'
                  : 'No devices connected',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
