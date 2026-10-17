import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/core/theme/app_typography.dart';
import 'package:desk_droid/features/guide/presentation/widgets/components/guide_card.dart';
import 'package:desk_droid/features/guide/presentation/widgets/components/guide_feature_bullet.dart';
import 'package:desk_droid/features/guide/presentation/widgets/components/guide_section_header.dart';
import 'package:flutter/material.dart';

/// Guide detailing productivity features: Finder drag & drop, clipboard sync, and audio forwarding.
class ProductivitySection extends StatelessWidget {
  const ProductivitySection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GuideSectionHeader(
          title: 'Productivity: Files, Clipboard & Audio',
          description: 'Mac-first conveniences designed for seamless cross-device workflows.',
        ),
        SizedBox(height: 16),

        GuideCard(
          badgeText: 'FINDER INTEGRATION',
          badgeColor: AppColors.accent,
          title: 'Drag & Drop Transfers & APK Sideloading',
          children: [
            Text(
              'Drag files directly from macOS Finder and drop them anywhere onto the DeskDroid screen:',
              style: AppTypography.body,
            ),
            SizedBox(height: 10),
            GuideFeatureBullet(
              icon: Icons.file_download_rounded,
              text: 'Standard Files (Photos, Videos, PDFs): Automatically saved to /sdcard/Download/ on your phone.',
            ),
            GuideFeatureBullet(
              icon: Icons.android_rounded,
              text: 'APK Packages (.apk): Automatically sideloaded and installed onto your phone with live progress.',
            ),
          ],
        ),
        SizedBox(height: 16),

        GuideCard(
          badgeText: 'AUTOMATIC SYNC',
          badgeColor: AppColors.statusSuccess,
          title: 'Bidirectional Clipboard Sharing',
          children: [
            Text(
              'Copy text on your Mac (Cmd + C) and immediately paste it on Android, or copy text on Android and paste on Mac. Sync runs automatically in the background.',
              style: AppTypography.body,
            ),
          ],
        ),
        SizedBox(height: 16),

        GuideCard(
          badgeText: 'AUDIO PIPELINE',
          badgeColor: AppColors.statusInfo,
          title: 'Low-Latency Audio Forwarding',
          children: [
            Text(
              'Game, video, and notification audio is forwarded directly to your Mac speakers over high-fidelity Opus/PCM 48kHz stereo. Adjust volume or mute on the floating HUD toolbar.',
              style: AppTypography.body,
            ),
          ],
        ),
      ],
    );
  }
}
