import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:wifi_desk/core/theme/app_colors.dart';
import 'package:wifi_desk/core/theme/app_typography.dart';
import 'package:wifi_desk/features/discovery/presentation/widgets/pairing/pairing_step_item.dart';

/// Tab view displaying high-contrast QR code and steps for Android 11+ pairing camera scan.
class PairingQrCodeTab extends StatelessWidget {
  const PairingQrCodeTab({
    super.key,
    required this.qrPayload,
    required this.pairingCode,
    required this.onRegenerateCode,
  });

  final String qrPayload;
  final String pairingCode;
  final VoidCallback onRegenerateCode;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Instructions for QR scanning
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How to pair using QR code:',
                style: AppTypography.subtitle.copyWith(fontSize: 12),
              ),
              const SizedBox(height: 6),
              const PairingStepItem(
                number: '1',
                text: 'Open Settings ➔ Developer Options ➔ Wireless Debugging.',
              ),
              const PairingStepItem(
                number: '2',
                text: 'Tap "Pair device with QR code" (Ghép nối bằng mã QR).',
              ),
              const PairingStepItem(
                number: '3',
                text: 'Point your phone camera at the QR code below to scan.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // QR Code Container with High-Contrast White Background
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: QrImageView(
              data: qrPayload,
              version: QrVersions.auto,
              size: 180.0,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Colors.black,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.black,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // PIN & Refresh Helper
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Pairing PIN: ',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              pairingCode,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: AppColors.accentLight,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 16),
              tooltip: 'Generate New QR Code',
              onPressed: onRegenerateCode,
            ),
          ],
        ),
      ],
    );
  }
}
