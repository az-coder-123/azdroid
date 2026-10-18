import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/features/showcase/domain/entities/app_feature_item.dart';
import 'package:flutter/material.dart';

/// Keyboard shortcuts and mouse gestures reference features in the showcase dialog.
const List<AppFeatureItem> showcaseShortcutsFeatures = [
  AppFeatureItem(
    id: 'shortcuts_master',
    title: 'Keyboard Shortcuts & Hotkeys Master',
    subtitle:
        'Complete hotkey reference for keyboard-first desktop productivity',
    category: FeatureCategory.shortcuts,
    icon: Icons.keyboard_command_key_rounded,
    badgeText: '⌘ Keys • Hotkeys',
    badgeColor: AppColors.accent,
    highlights: [
      'Core: ⌘K (Text Injector), ⌘O (Screen Toggle), ⌘R (Rotate), ⌘H (Home), ⌘⌫ (Back).',
      'Media: ⌘S (Screenshot), ⌘⇧S (Area Crop), ⌘⇧R (Screen Record), ⌘U (Send Files).',
      'Developer: ⌘⇧L (Logcat), ⌘⇧D (Intent Dispatcher), ⌘⇧I (Install APK), ⌘⇧F (Files).',
      'Clipboard: ⌘⇧C (Push to Phone) and ⌘⇧V (Pull to Mac).',
    ],
    proTip: 'All shortcuts use the Cmd modifier for fast navigation. Right-click anywhere for Back.',
    docFileName: 'shortcuts.md',
  ),
  AppFeatureItem(
    id: 'mouse_gestures',
    title: 'Trackpad & Mouse Gestures Reference',
    subtitle:
        'Fluid touch physics, pinch-zoom, and multi-button mouse navigation',
    category: FeatureCategory.shortcuts,
    icon: Icons.touch_app_rounded,
    badgeText: 'Gestures • Multi-Touch',
    badgeColor: AppColors.accentLight,
    highlights: [
      'Left Click: Primary Android touch; Left Drag: Natural swipe and scroll motion.',
      'Right Click: Instant Android Back navigation; Middle Click: Android Home.',
      'Trackpad 2-Finger Pan: Live scrolling with realistic inertia and flings.',
      'Trackpad Pinch or Alt+Drag: Smooth pinch-to-zoom and two-finger rotation.',
    ],
    proTip: 'Right-clicking anywhere on the screen instantly acts as Android Back button.',
    docFileName: 'shortcuts.md',
  ),
];
