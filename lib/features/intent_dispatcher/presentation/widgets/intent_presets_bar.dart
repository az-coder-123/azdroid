import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Preset template defining common Android Intent and Deep Link configurations.
class IntentPreset {
  const IntentPreset({
    required this.label,
    required this.icon,
    required this.action,
    required this.dataUri,
  });

  final String label;
  final IconData icon;
  final String action;
  final String dataUri;
}

/// Horizontal scrollable bar providing fast 1-click preset templates for testing.
class IntentPresetsBar extends StatelessWidget {
  const IntentPresetsBar({required this.onSelectPreset, super.key});

  final void Function(IntentPreset preset) onSelectPreset;

  static const List<IntentPreset> presets = [
    IntentPreset(
      label: 'HTTPS Web',
      icon: Icons.language_rounded,
      action: 'android.intent.action.VIEW',
      dataUri: 'https://flutter.dev',
    ),
    IntentPreset(
      label: 'Play Store',
      icon: Icons.shop_two_rounded,
      action: 'android.intent.action.VIEW',
      dataUri: 'market://details?id=com.google.android.youtube',
    ),
    IntentPreset(
      label: 'Geo Map',
      icon: Icons.place_rounded,
      action: 'android.intent.action.VIEW',
      dataUri: 'geo:37.7749,-122.4194',
    ),
    IntentPreset(
      label: 'Phone Call',
      icon: Icons.phone_rounded,
      action: 'android.intent.action.VIEW',
      dataUri: 'tel:+1234567890',
    ),
    IntentPreset(
      label: 'Custom App Link',
      icon: Icons.link_rounded,
      action: 'android.intent.action.VIEW',
      dataUri: 'myapp://product/456?ref=azdroid',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: presets.map((preset) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              avatar: Icon(preset.icon, size: 14, color: AppColors.accent),
              label: Text(
                preset.label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textPrimary,
                ),
              ),
              backgroundColor: AppColors.surfaceElevated,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              onPressed: () => onSelectPreset(preset),
            ),
          );
        }).toList(),
      ),
    );
  }
}
