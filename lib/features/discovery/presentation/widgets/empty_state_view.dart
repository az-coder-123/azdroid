import 'package:flutter/material.dart';
import 'package:wifi_desk/core/di/injection.dart';
import 'package:wifi_desk/core/services/network_info_service.dart';
import 'package:wifi_desk/core/theme/app_colors.dart';
import 'package:wifi_desk/core/theme/app_typography.dart';

/// Clean placeholder view displayed when no devices are detected on the network,
/// providing host Wi-Fi IP context and quick actions for scanning and QR pairing.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.isScanning,
    required this.onScanPressed,
    this.onPairWithQrPressed,
    this.onGuidePressed,
  });

  final bool isScanning;
  final VoidCallback onScanPressed;
  final VoidCallback? onPairWithQrPressed;
  final VoidCallback? onGuidePressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 540),
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
            const SizedBox(height: 16),

            // Mac Local Wi-Fi IP Pill
            FutureBuilder<String?>(
              future: sl.isRegistered<NetworkInfoService>()
                  ? sl<NetworkInfoService>().getLocalIpAddress()
                  : Future.value(null),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data == null) {
                  return const SizedBox.shrink();
                }
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.wifi_rounded,
                        size: 14,
                        color: AppColors.statusSuccess,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Your Mac Wi-Fi IP: ${snapshot.data}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 28),

            // Action Buttons
            Wrap(
              spacing: 12,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
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
                if (onPairWithQrPressed != null)
                  OutlinedButton.icon(
                    onPressed: onPairWithQrPressed,
                    icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                    label: const Text('Pair with QR Code'),
                  ),
                if (onGuidePressed != null)
                  TextButton.icon(
                    onPressed: onGuidePressed,
                    icon: const Icon(Icons.menu_book_rounded, size: 18),
                    label: const Text('User Guide'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
