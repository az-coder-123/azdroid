import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/features/showcase/domain/entities/app_feature_item.dart';
import 'package:flutter/material.dart';

/// Display and remote control features presented in the showcase dialog.
const List<AppFeatureItem> showcaseDisplayControlFeatures = [
  AppFeatureItem(
    id: 'mirroring',
    title: 'Wireless Screen Mirroring',
    subtitle: 'Low-latency hardware-decoded streaming at up to 60 FPS over Wi-Fi or USB',
    category: FeatureCategory.displayAndControl,
    icon: Icons.cast_connected_rounded,
    badgeText: 'Up to 60 FPS • H.264',
    badgeColor: AppColors.accent,
    highlights: [
      'Hardware decoding: VideoToolbox on macOS, Media Foundation on Windows.',
      'Streams at the phone\'s native resolution, sharp on high-DPI displays.',
      'Automatic portrait/landscape orientation sync with the mobile device.',
    ],
    proTip: 'Pick 4, 8, or 16 Mbps in the side dock: 4 Mbps for weak Wi-Fi.',
    docFileName: 'wireless-display-streaming.md',
  ),
  AppFeatureItem(
    id: 'screen_off',
    title: 'Screen-Off Mirroring',
    subtitle: 'Stream and control while the physical Android screen is powered down (Cmd+O)',
    category: FeatureCategory.displayAndControl,
    icon: Icons.screen_lock_portrait_rounded,
    badgeText: '⌘O • Power Saver',
    badgeColor: AppColors.statusSuccess,
    highlights: [
      'Phone display stays completely black while remaining fully interactive on Mac.',
      'Saves up to 70% device battery and prevents device overheating.',
      'Privacy protection prevents shoulder-surfing in public workspaces.',
    ],
    proTip: 'Press Cmd+O or click the screen toggle button in the left dock.',
    docFileName: 'screen-off-streaming.md',
  ),
  AppFeatureItem(
    id: 'text_injector',
    title: 'Quick Text Injector (Cmd+K)',
    subtitle: 'Type or paste Vietnamese accents, CJK, Emoji, and multiline text cleanly',
    category: FeatureCategory.displayAndControl,
    icon: Icons.keyboard_alt_rounded,
    badgeText: '⌘K • Text Injector',
    badgeColor: AppColors.accent,
    highlights: [
      'Modal input field to send text in any language without character corruption.',
      'Bypasses scrcpy ASCII keycode limitation by pasting via phone clipboard.',
      'Ideal for Vietnamese Telex/VNI, long passwords, API tokens, and URLs.',
    ],
    proTip:
        'Press Cmd+K anywhere while mirroring to pop up the text input dialog.',
    docFileName: 'remote-input-control.md',
  ),
  AppFeatureItem(
    id: 'rotate_screen',
    title: 'Rotate Screen Viewport (Cmd+R)',
    subtitle: 'Instantly rotate display orientation 90° clockwise with touch re-mapping',
    category: FeatureCategory.displayAndControl,
    icon: Icons.screen_rotation_rounded,
    badgeText: '⌘R • Rotate Viewport',
    badgeColor: AppColors.accentLight,
    highlights: [
      'Rotates the mirroring display viewport 90° clockwise on demand.',
      'Perfect for testing landscape games, spreadsheets, and video playback.',
      'Automatically recalculates aspect ratio and touch coordinate mappings.',
    ],
    proTip: 'Press Cmd+R or click the rotate icon in the left toolbar.',
    docFileName: 'wireless-display-streaming.md',
  ),
  AppFeatureItem(
    id: 'remote_control',
    title: 'Mouse & Mac Keyboard Navigation',
    subtitle: 'Natural desktop ergonomics for seamless Android navigation',
    category: FeatureCategory.displayAndControl,
    icon: Icons.mouse_rounded,
    badgeText: '⌘H / ⌘⌫ • System Nav',
    badgeColor: AppColors.accentLight,
    highlights: [
      'Shortcuts: Cmd+H for Android Home, Cmd+Backspace (or Esc) for Back.',
      'Right-click anywhere acts as Android Back; middle-click triggers Home.',
      'Trackpad 2-finger live drag & fling; Alt+drag pinches with a mouse.',
    ],
    proTip: 'Right-click is the fastest way to dismiss dialogs or go back on Android.',
    docFileName: 'remote-input-control.md',
  ),
  AppFeatureItem(
    id: 'audio_forwarding',
    title: 'Real-Time Audio Forwarding',
    subtitle: 'Stream device audio directly to Mac speakers with zero sync lag',
    category: FeatureCategory.displayAndControl,
    icon: Icons.volume_up_rounded,
    badgeText: 'Audio • Low Latency',
    badgeColor: AppColors.statusSuccess,
    highlights: [
      'Streams internal audio from Android 12+ directly to host computer speakers.',
      'CoreAudio native rendering on macOS for pristine synchronization with video.',
      'Interactive volume slider and 1-click mute toggle in the mirroring dock.',
    ],
    proTip: 'Click the speaker icon in the left controls dock to adjust or mute forwarded audio.',
    docFileName: 'audio-forwarding.md',
  ),
];
