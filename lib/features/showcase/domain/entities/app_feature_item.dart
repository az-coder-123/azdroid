import 'package:flutter/material.dart';

/// Categories classifying features in DeskDroid for intuitive browsing.
enum FeatureCategory {
  all(label: 'All Features', icon: Icons.apps_rounded),
  displayAndControl(
    label: 'Display & Control',
    icon: Icons.cast_connected_rounded,
  ),
  devTools(label: 'Developer Tools', icon: Icons.terminal_rounded),
  productivity(
    label: 'Productivity & Media',
    icon: Icons.folder_shared_rounded,
  ),
  connectivity(
    label: 'Connectivity & System',
    icon: Icons.wifi_tethering_rounded,
  ),
  shortcuts(
    label: 'Shortcuts & Gestures',
    icon: Icons.keyboard_command_key_rounded,
  );

  const FeatureCategory({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

/// Entity describing an individual feature in the DeskDroid application.
class AppFeatureItem {
  const AppFeatureItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.icon,
    required this.badgeText,
    required this.badgeColor,
    required this.highlights,
    required this.proTip,
    required this.docFileName,
  });

  final String id;
  final String title;
  final String subtitle;
  final FeatureCategory category;
  final IconData icon;
  final String badgeText;
  final Color badgeColor;
  final List<String> highlights;
  final String proTip;
  final String docFileName;
}
