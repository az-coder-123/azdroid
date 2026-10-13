import 'package:flutter/material.dart';
import 'package:wifi_desk/core/theme/app_colors.dart';
import 'package:wifi_desk/core/theme/app_typography.dart';
import 'package:wifi_desk/features/discovery/presentation/widgets/pairing/pairing_step_item.dart';

/// Tab view for manual 6-digit PIN input with Phone IP and pairing port fields.
class PairingManualCodeTab extends StatelessWidget {
  const PairingManualCodeTab({
    super.key,
    required this.isSubmitting,
    required this.hostMacIp,
    required this.ipController,
    required this.portController,
    required this.codeController,
  });

  final bool isSubmitting;
  final String? hostMacIp;
  final TextEditingController ipController;
  final TextEditingController portController;
  final TextEditingController codeController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Instructional Guide Banner
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
                'Manual PIN Entry Guide:',
                style: AppTypography.subtitle.copyWith(fontSize: 12),
              ),
              const SizedBox(height: 6),
              const PairingStepItem(
                number: '1',
                text: 'Open Settings ➔ Developer Options ➔ Wireless Debugging.',
              ),
              const PairingStepItem(
                number: '2',
                text: 'Tap "Pair device with pairing code".',
              ),
              const PairingStepItem(
                number: '3',
                text: 'Enter the phone IP, pairing port, and 6-digit code shown on screen.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Form Fields: Phone IP & Port
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: ipController,
                enabled: !isSubmitting,
                decoration: InputDecoration(
                  labelText: 'Phone IP Address',
                  hintText: hostMacIp != null
                      ? 'e.g. ${hostMacIp!.substring(0, hostMacIp!.lastIndexOf('.') + 1)}xxx'
                      : '192.168.1.100',
                  helperText: 'View on phone under Wireless Debugging',
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: TextField(
                controller: portController,
                enabled: !isSubmitting,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Pairing Port',
                  hintText: '37123',
                  helperText: 'Port displayed with PIN',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Form Field: 6-Digit Pairing Code
        TextField(
          controller: codeController,
          enabled: !isSubmitting,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: AppTypography.title.copyWith(
            letterSpacing: 8.0,
            fontWeight: FontWeight.bold,
          ),
          decoration: const InputDecoration(
            labelText: '6-Digit Pairing Code',
            hintText: '123456',
            counterText: '',
            isDense: true,
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}
