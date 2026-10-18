import 'package:desk_droid/core/platform/shortcuts/shortcut_scheme.dart';
import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/features/guide/presentation/widgets/components/guide_card.dart';
import 'package:desk_droid/features/guide/presentation/widgets/components/guide_gesture_item.dart';
import 'package:desk_droid/features/guide/presentation/widgets/components/guide_section_header.dart';
import 'package:desk_droid/features/guide/presentation/widgets/components/guide_shortcut_item.dart';
import 'package:flutter/material.dart';

/// Guide detailing mouse, trackpad gestures and macOS keyboard shortcuts.
class ControlsSection extends StatelessWidget {
  const ControlsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final keys = context.shortcuts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const GuideSectionHeader(
          title: 'Mouse & Keyboard Gestures',
          description: 'Natural desktop gestures mapped seamlessly to Android touch and hardware keys.',
        ),
        const SizedBox(height: 16),

        const GuideCard(
          badgeText: 'MOUSE ACTIONS',
          badgeColor: AppColors.accent,
          title: 'Mouse & Trackpad Mapping',
          children: [
            GuideGestureItem(
              icon: Icons.mouse_rounded,
              title: 'Left Click & Drag',
              action: 'Tap, swipe, flick, and drag across the screen naturally',
            ),
            GuideGestureItem(
              icon: Icons.touch_app_rounded,
              title: 'Right Click',
              action: 'Triggers Android System BACK button',
            ),
            GuideGestureItem(
              icon: Icons.radio_button_checked_rounded,
              title: 'Middle Click / Scroll Wheel Click',
              action: 'Triggers Android System HOME button',
            ),
            GuideGestureItem(
              icon: Icons.swap_vert_rounded,
              title: 'Mouse Scroll / Trackpad 2 Fingers',
              action: 'Smooth vertical and horizontal list scrolling',
            ),
          ],
        ),
        const SizedBox(height: 16),

        GuideCard(
          badgeText: 'APPLE KEYBOARD SHORTCUTS',
          badgeColor: AppColors.statusSuccess,
          title: 'macOS Keyboard Navigation',
          children: [
            GuideShortcutItem(
              keys: keys.keyCaps('H'),
              description: 'Go to Home Screen',
            ),
            GuideShortcutItem(
              keys: keys.keyCaps('Backspace'),
              description: 'Back navigation key',
            ),
            GuideShortcutItem(
              keys: keys.keyCaps('Tab'),
              description: 'Open App Switcher (Recent Apps)',
            ),
            GuideShortcutItem(
              keys: keys.keyCaps('K'),
              description:
                  'Quick Text Injector (Direct Unicode & Vietnamese accents)',
            ),
            GuideShortcutItem(
              keys: keys.keyCaps('R'),
              description: 'Rotate screen display 90 degrees',
            ),
            GuideShortcutItem(
              keys: keys.keyCaps('O'),
              description: 'Turn phone screen off/on (mirroring continues)',
            ),
          ],
        ),
      ],
    );
  }
}
