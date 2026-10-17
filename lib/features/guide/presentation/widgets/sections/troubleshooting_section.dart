import 'package:desk_droid/features/guide/presentation/widgets/components/guide_faq_item.dart';
import 'package:desk_droid/features/guide/presentation/widgets/components/guide_section_header.dart';
import 'package:flutter/material.dart';

/// Troubleshooting and FAQ section covering connection errors and fixes.
class TroubleshootingSection extends StatelessWidget {
  const TroubleshootingSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GuideSectionHeader(
          title: 'Troubleshooting & Common Fixes',
          description: 'Quick solutions to common network and device authorization roadblocks.',
        ),
        SizedBox(height: 16),

        GuideFaqItem(
          question: '1. "No route to host" or cannot connect via Wi-Fi',
          answer: 'Make sure both Mac and Android are connected to the SAME Wi-Fi network. Public Wi-Fi networks (cafes, universities) often enable "AP Isolation" which blocks peer-to-peer devices. Use home Wi-Fi or create a Mac Wi-Fi Hotspot.',
        ),
        SizedBox(height: 12),

        GuideFaqItem(
          question: '2. Mouse clicks do nothing on Xiaomi / Redmi',
          answer: 'You must enable "USB debugging (Security settings)" in Developer options on your Xiaomi device. See the "Xiaomi / MIUI Setup" tab on the left for step-by-step instructions.',
        ),
        SizedBox(height: 12),

        GuideFaqItem(
          question: '3. Unplugging USB cable disconnects my phone',
          answer: 'On Android 10 and older, you must run "adb tcpip 5555" in Terminal WHILE the cable is still plugged in. Once successful, you can safely unplug and connect wirelessly via Direct IP.',
        ),
        SizedBox(height: 12),

        GuideFaqItem(
          question: '4. Device says "Unauthorized"',
          answer: 'Look at your phone screen and tap "Always allow from this computer" on the USB Debugging prompt, then tap OK.',
        ),
      ],
    );
  }
}
