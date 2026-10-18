import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/features/showcase/domain/entities/app_feature_item.dart';
import 'package:flutter/material.dart';

/// Productivity and media features presented in the showcase dialog.
const List<AppFeatureItem> showcaseProductivityFeatures = [
  AppFeatureItem(
    id: 'screenshot_full',
    title: 'Full-Resolution Screenshot (Cmd+S)',
    subtitle:
        'Capture lossless PNGs saved to Downloads & copied to Mac clipboard',
    category: FeatureCategory.productivity,
    icon: Icons.camera_alt_rounded,
    badgeText: '⌘S • Instant Capture',
    badgeColor: AppColors.accent,
    highlights: [
      'Instant lossless PNG capture at the source Android device resolution.',
      'Auto-saved directly to your Mac ~/Downloads folder with timestamp.',
      'Automatically copied to macOS pasteboard for pasting into Slack, Figma, or Jira.',
    ],
    proTip: 'Press Cmd+S or click the camera button on the dock.',
    docFileName: 'screenshots-area-crop.md',
  ),
  AppFeatureItem(
    id: 'screenshot_crop',
    title: 'Interactive Area Crop (Cmd+Shift+S)',
    subtitle:
        'Drag marquee selection with pixel dimension badges and keyboard keys',
    category: FeatureCategory.productivity,
    icon: Icons.crop_rounded,
    badgeText: '⌘⇧S • Area Crop',
    badgeColor: AppColors.accentLight,
    highlights: [
      'Interactive draggable marquee with real-time width & height pixel badges.',
      'Keyboard keys: C to Copy to clipboard, S to Save to file, Enter for both.',
      'Floating action toolbar positions adaptively to avoid obscuring content.',
    ],
    proTip: 'Press Cmd+Shift+S to start crop mode anytime.',
    docFileName: 'screenshots-area-crop.md',
  ),
  AppFeatureItem(
    id: 'screen_recording',
    title: 'Hardware Screen Recording (Cmd+Shift+R)',
    subtitle: 'H.264 MP4 recording encoded on the phone, not the computer',
    category: FeatureCategory.productivity,
    icon: Icons.videocam_rounded,
    badgeText: '⌘⇧R • MP4 Record',
    badgeColor: AppColors.statusError,
    highlights: [
      'Encoded by the phone\'s hardware encoder; the computer only pulls the file.',
      'Records at 8 Mbps for up to 3 minutes with a 3-second countdown timer.',
      'Clean SIGINT process finalization ensures valid MP4 moov atom header.',
    ],
    proTip: 'Press Cmd+Shift+R to start or stop recording.',
    docFileName: 'hardware-screen-recording.md',
  ),
  AppFeatureItem(
    id: 'file_manager',
    title: 'Device File Manager (Cmd+Shift+F)',
    subtitle: 'Browse Android storage and transfer files in both directions',
    category: FeatureCategory.productivity,
    icon: Icons.folder_shared_rounded,
    badgeText: '⌘⇧F • Two-Way Explorer',
    badgeColor: AppColors.accent,
    highlights: [
      'Inspect both Internal Storage (/sdcard) and external MicroSD storage paths.',
      'Multi-file batch download straight to your Mac Downloads folder.',
      'Fast search bar to locate APKs, DCIM photos, and documents instantly.',
    ],
    proTip: 'Press Cmd+Shift+F to open the file manager.',
    docFileName: 'file-transfer-explorer.md',
  ),
  AppFeatureItem(
    id: 'fast_file_push',
    title: 'Fast File Push (Cmd+U)',
    subtitle:
        'Send files, media, or APKs to Android storage via native file picker',
    category: FeatureCategory.productivity,
    icon: Icons.upload_file_rounded,
    badgeText: '⌘U • Send Files',
    badgeColor: AppColors.accentLight,
    highlights: [
      'Opens macOS Finder or Windows File Explorer native file picker dialog.',
      'Pushes selected files directly to /sdcard/Download/ on the Android device.',
      'Shows real-time progress banner with uploaded file name and size.',
    ],
    proTip: 'Press Cmd+U to pick files without opening the full file manager.',
    docFileName: 'file-transfer-explorer.md',
  ),
  AppFeatureItem(
    id: 'viewport_drag_drop',
    title: 'Direct Viewport Drag & Drop',
    subtitle: 'Drop files, folders, or APKs directly onto the screen for instant transfer',
    category: FeatureCategory.productivity,
    icon: Icons.file_download_outlined,
    badgeText: 'Zero-Click Drop',
    badgeColor: AppColors.accentLight,
    highlights: [
      'Drop photos, videos, and folders to push directly to /sdcard/Download/.',
      'Drop .apk packages for zero-click background installation without modal interruption.',
      'Real-time frosted-glass hover highlight with self-dismissing transfer HUD.',
    ],
    proTip: 'Drag-and-drop covers 100% of the window in both Standard and Zen modes.',
    docFileName: 'file-transfer-explorer.md',
  ),
  AppFeatureItem(
    id: 'clipboard_sync',
    title: 'Two-Way Clipboard Sync (Cmd+Shift+C / V)',
    subtitle:
        'Background clipboard sync between computer and Android every 2 s',
    category: FeatureCategory.productivity,
    icon: Icons.content_paste_go_rounded,
    badgeText: '⌘⇧C / ⌘⇧V • Live Sync',
    badgeColor: AppColors.statusSuccess,
    highlights: [
      'Automatic background sync daemon detects copied text on Mac and Android.',
      'Bidirectional echo-loop prevention ensures zero repetitive ping-pong copying.',
      'Manual hotkeys: Cmd+Shift+C (Push to Phone) and Cmd+Shift+V (Pull to Mac).',
    ],
    proTip: 'Toggle or pause auto-sync from the clipboard icon on the right dock at any time.',
    docFileName: 'clipboard-sync.md',
  ),
];
