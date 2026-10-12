import 'package:flutter/material.dart';
import 'package:wifi_desk/core/theme/app_colors.dart';
import 'package:wifi_desk/core/theme/app_typography.dart';
import 'package:wifi_desk/features/guide/presentation/widgets/components/guide_card.dart';
import 'package:wifi_desk/features/guide/presentation/widgets/components/guide_command_snippet.dart';
import 'package:wifi_desk/features/guide/presentation/widgets/components/guide_section_header.dart';
import 'package:wifi_desk/features/guide/presentation/widgets/components/guide_step_row.dart';

/// Quick start guide explaining 3 wireless connection modes (QR, USB activation, Direct IP).
class QuickStartSection extends StatelessWidget {
  const QuickStartSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const GuideSectionHeader(
          title: 'Quick Start & 3 Connection Modes',
          description: 'Choose the setup method best suited for your Android version and network configuration.',
        ),
        const SizedBox(height: 16),

        const GuideCard(
          badgeText: 'RECOMMENDED • ANDROID 11+',
          badgeColor: AppColors.statusSuccess,
          title: 'Method 1: Scan QR Code (100% Wireless)',
          children: [
            Text(
              'Android 11+ supports native wireless pairing without ever touching a USB cable.',
              style: AppTypography.body,
            ),
            SizedBox(height: 10),
            GuideStepRow(
              number: '1',
              text: 'On Phone: Go to Settings ➔ Developer Options ➔ Wireless Debugging.',
            ),
            GuideStepRow(
              number: '2',
              text: 'Select "Pair device with QR code" (Ghép nối bằng mã QR).',
            ),
            GuideStepRow(
              number: '3',
              text: 'On WifiDesk: Click "Pair Device" on the top bar and scan the displayed QR code with your phone camera.',
            ),
            GuideStepRow(
              number: '4',
              text: 'The phone pairs immediately and appears in the Discovered Devices list!',
            ),
          ],
        ),
        const SizedBox(height: 16),

        const GuideCard(
          badgeText: 'BEST FOR ANDROID 10 & OLDER • XIAOMI / REDMI',
          badgeColor: AppColors.accent,
          title: 'Method 2: One-Time USB Activation (adb tcpip 5555)',
          children: [
            Text(
              'For Android 10 or phones without a Wireless Debugging menu, activate wireless mode in 5 seconds via USB:',
              style: AppTypography.body,
            ),
            SizedBox(height: 10),
            GuideStepRow(
              number: '1',
              text: 'Plug your phone into Mac via USB cable, and enable USB Debugging on the phone.',
            ),
            GuideStepRow(
              number: '2',
              text: 'Open Terminal on Mac and run the following command:',
            ),
            SizedBox(height: 6),
            GuideCommandSnippet(command: 'adb tcpip 5555'),
            SizedBox(height: 8),
            GuideStepRow(
              number: '3',
              text: 'Unplug the USB cable. Your phone is now listening over local Wi-Fi port 5555!',
            ),
            GuideStepRow(
              number: '4',
              text: 'On WifiDesk: Click "Direct IP", enter your phone IP (e.g. 192.168.1.3:5555) and connect.',
            ),
          ],
        ),
        const SizedBox(height: 16),

        const GuideCard(
          badgeText: 'DIRECT CONNECTION',
          badgeColor: AppColors.statusInfo,
          title: 'Method 3: Direct IP Connection',
          children: [
            Text(
              'Connect directly to any device already on your local Wi-Fi with an open ADB port.',
              style: AppTypography.body,
            ),
            SizedBox(height: 10),
            GuideStepRow(
              number: '1',
              text: 'Find your phone IP address in Phone Settings ➔ Wi-Fi ➔ Current Network (e.g. 192.168.1.3).',
            ),
            GuideStepRow(
              number: '2',
              text: 'Click "Direct IP" on WifiDesk, enter the IP and port (default 5555), and click Connect.',
            ),
          ],
        ),
      ],
    );
  }
}
