import 'package:flutter/material.dart';
import 'package:wifi_desk/core/theme/app_colors.dart';

/// Modal dialog header displaying title, target device serial, and close action.
class IntentDispatcherHeader extends StatelessWidget {
  const IntentDispatcherHeader({
    required this.deviceSerial,
    required this.onClose,
    super.key,
  });

  final String deviceSerial;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.alt_route_rounded,
              size: 18,
              color: AppColors.accentLight,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Deep Link & Intent Dispatcher',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Device: $deviceSerial',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.close_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}
