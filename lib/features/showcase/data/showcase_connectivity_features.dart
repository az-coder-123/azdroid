import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/features/showcase/domain/entities/app_feature_item.dart';
import 'package:flutter/material.dart';

/// Connectivity, discovery, and system features presented in the showcase dialog.
const List<AppFeatureItem> showcaseConnectivityFeatures = [
  AppFeatureItem(
    id: 'pairing',
    title: 'Wireless Discovery & Pairing',
    subtitle:
        'Automated network discovery and seamless 1-click USB-to-Wi-Fi switch',
    category: FeatureCategory.connectivity,
    icon: Icons.wifi_tethering_rounded,
    badgeText: 'mDNS Auto-Discovery',
    badgeColor: AppColors.accent,
    highlights: [
      'Finds devices on the local subnet via ARP, TCP port sweep, and mDNS.',
      '1-click switch from wired USB connection to permanent wireless Wi-Fi mode.',
      'Supports pairing via 6-digit Wi-Fi PIN code or direct IP socket entry.',
    ],
    proTip:
        'Connect via USB once to authorize ADB, then unplug and stay wireless!',
    docFileName: 'device-discovery-pairing.md',
  ),
  AppFeatureItem(
    id: 'menu_bar',
    title: 'macOS Menu Bar Companion',
    subtitle:
        'Planned: status telemetry and quick toggles in the macOS menu bar',
    category: FeatureCategory.connectivity,
    icon: Icons.desktop_mac_rounded,
    badgeText: 'Planned',
    badgeColor: AppColors.textSecondary,
    highlights: [
      'Lightweight background companion displaying the active connected device.',
      'Real-time FPS and network latency (ms) telemetry monitor.',
      '1-click toggle to show or hide the main mirroring window instantly.',
    ],
    proTip: 'Not available yet: the popover is designed but not wired into the app.',
    docFileName: 'menu-bar-companion.md',
  ),
];
