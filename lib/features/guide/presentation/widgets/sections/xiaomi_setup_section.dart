import 'package:flutter/material.dart';
import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/core/theme/app_typography.dart';
import 'package:desk_droid/features/guide/presentation/widgets/components/guide_callout.dart';
import 'package:desk_droid/features/guide/presentation/widgets/components/guide_card.dart';
import 'package:desk_droid/features/guide/presentation/widgets/components/guide_section_header.dart';
import 'package:desk_droid/features/guide/presentation/widgets/components/guide_step_row.dart';

/// Specific instructions for Xiaomi / MIUI / HyperOS permission setup (Redmi 9, etc.).
class XiaomiSetupSection extends StatelessWidget {
  const XiaomiSetupSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const GuideSectionHeader(
          title: 'Xiaomi / MIUI / HyperOS Setup',
          description: 'Xiaomi devices enforce strict security layers that require explicit permissions to allow mouse & keyboard interaction.',
        ),
        const SizedBox(height: 16),

        const GuideCallout(
          icon: Icons.warning_amber_rounded,
          color: AppColors.statusWarning,
          title: 'Critical: Enable "Security Settings" for Mouse Control',
          message: 'Without this setting, you can see the screen, but mouse clicks and keyboard typing will NOT register on Xiaomi phones.',
        ),
        const SizedBox(height: 16),

        GuideCard(
          badgeText: 'STEP-BY-STEP CHECKLIST',
          badgeColor: AppColors.accent,
          title: 'Xiaomi Permission Configuration',
          children: [
            const GuideStepRow(
              number: '1',
              text: 'Enable Developer Options: Go to Settings ➔ About Phone ➔ Tap "MIUI version" 7 times rapidly until you see "You are now a developer!".',
            ),
            const GuideStepRow(
              number: '2',
              text: 'Open Settings ➔ Additional settings ➔ Developer options.',
            ),
            const GuideStepRow(number: '3', text: 'Toggle ON: USB debugging.'),
            const GuideStepRow(
              number: '4',
              text: 'Toggle ON: USB debugging (Security settings).',
            ),
            Padding(
              padding: const EdgeInsets.only(left: 28, top: 4, bottom: 8),
              child: Text(
                '• Note: MIUI may require inserting a SIM card or logging into a Mi Account once to authorize this. Accept the three 5-second security warnings.',
                style: AppTypography.caption.copyWith(
                  color: AppColors.statusWarning,
                ),
              ),
            ),
            const GuideStepRow(
              number: '5',
              text: 'Optional: Toggle OFF "MIUI Optimization" at the bottom of Developer options if mirroring randomly disconnects in background.',
            ),
          ],
        ),
      ],
    );
  }
}
