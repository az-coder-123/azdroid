import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/core/theme/app_typography.dart';
import 'package:desk_droid/features/guide/presentation/widgets/components/guide_card.dart';
import 'package:desk_droid/features/guide/presentation/widgets/components/guide_section_header.dart';
import 'package:desk_droid/features/guide/presentation/widgets/components/guide_step_row.dart';
import 'package:flutter/material.dart';

/// Quick start guide explaining 3 realistic connection modes (1-Click USB switch, 6-Digit PIN, Direct IP).
class QuickStartSection extends StatelessWidget {
  const QuickStartSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GuideSectionHeader(
          title: 'Quick Start & 3 Connection Modes',
          description: 'Choose the setup method best suited for your Android device and network setup.',
        ),
        SizedBox(height: 16),

        GuideCard(
          badgeText: 'RECOMMENDED • 1-CLICK WIRELESS SETUP',
          badgeColor: AppColors.statusSuccess,
          title: 'Method 1: 1-Click USB to Wi-Fi Switch (Easiest)',
          children: [
            Text(
              'Convert any USB connection into wireless mode instantly without touching Terminal:',
              style: AppTypography.body,
            ),
            SizedBox(height: 10),
            GuideStepRow(
              number: '1',
              text: 'Plug your phone into Mac via USB cable and allow USB debugging when prompted.',
            ),
            GuideStepRow(
              number: '2',
              text: 'DeskDroid will detect your USB device and display a "Wi-Fi Mode" button.',
            ),
            GuideStepRow(
              number: '3',
              text: 'Click "Wi-Fi Mode". DeskDroid automatically retrieves the phone Wi-Fi IP, activates port 5555, and connects.',
            ),
            GuideStepRow(
              number: '4',
              text: 'Unplug the USB cable! Your phone remains connected wirelessly.',
            ),
          ],
        ),
        SizedBox(height: 16),

        GuideCard(
          badgeText: 'ANDROID 11+ • CABLE-FREE PAIRING',
          badgeColor: AppColors.accent,
          title: 'Method 2: 6-Digit Wi-Fi Pairing Code',
          children: [
            Text(
              'Android 11+ native wireless pairing without any USB cable:',
              style: AppTypography.body,
            ),
            SizedBox(height: 10),
            GuideStepRow(
              number: '1',
              text: 'On Phone: Settings ➔ Developer Options ➔ Wireless Debugging.',
            ),
            GuideStepRow(
              number: '2',
              text: 'Tap "Pair device with pairing code".',
            ),
            GuideStepRow(
              number: '3',
              text: 'On DeskDroid: Click "Pair with Wi-Fi Code" on top bar, then enter the IP, pairing port, and 6-digit code shown on screen.',
            ),
            GuideStepRow(
              number: '4',
              text: 'Click "Pair & Connect" — phone is paired and ready to mirror.',
            ),
          ],
        ),
        SizedBox(height: 16),

        GuideCard(
          badgeText: 'INSTANT RECONNECT',
          badgeColor: AppColors.statusInfo,
          title: 'Method 3: Direct IP Connection & Recent Devices',
          children: [
            Text(
              'Connect directly to any device already listening on your Wi-Fi network:',
              style: AppTypography.body,
            ),
            SizedBox(height: 10),
            GuideStepRow(
              number: '1',
              text: 'If you connected before, simply tap the device under "Recent Devices" to reconnect in 1 click.',
            ),
            GuideStepRow(
              number: '2',
              text: 'Or click "Direct IP" on DeskDroid, enter your phone Wi-Fi IP (e.g. 192.168.1.100:5555), and click Connect.',
            ),
          ],
        ),
      ],
    );
  }
}
