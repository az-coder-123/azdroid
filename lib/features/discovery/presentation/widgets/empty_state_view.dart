import 'package:flutter/material.dart';
import 'package:wifi_desk/core/theme/app_colors.dart';
import 'package:wifi_desk/core/theme/app_typography.dart';

/// Clean placeholder view displayed when no devices are detected on the network.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.isScanning,
    required this.onScanPressed,
  });

  final bool isScanning;
  final VoidCallback onScanPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.devices_other_rounded,
                size: 40,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Devices Discovered',
              style: AppTypography.display,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Make sure your Android device has Wireless Debugging enabled and is connected to the same local Wi-Fi network.',
              style: AppTypography.subtitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: isScanning ? null : onScanPressed,
              icon: isScanning
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                isScanning ? 'Scanning Network...' : 'Scan for Devices',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
