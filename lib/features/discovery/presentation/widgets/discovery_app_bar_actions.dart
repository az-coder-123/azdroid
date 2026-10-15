import 'package:flutter/material.dart';
import 'package:wifi_desk/core/theme/app_colors.dart';

/// Responsive actions toolbar rendered in the DiscoveryPage AppBar following macOS HIG.
class DiscoveryAppBarActions extends StatelessWidget {
  const DiscoveryAppBarActions({
    super.key,
    required this.onPairDevice,
    required this.onDirectIp,
    required this.onShowcase,
    required this.onUserGuide,
    required this.onRescan,
  });

  final VoidCallback onPairDevice;
  final VoidCallback onDirectIp;
  final VoidCallback onShowcase;
  final VoidCallback onUserGuide;
  final VoidCallback onRescan;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 640;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (compact)
          IconButton(
            tooltip: 'Pair Device',
            icon: const Icon(
              Icons.phonelink_setup_rounded,
              color: AppColors.accent,
              size: 20,
            ),
            splashRadius: 20,
            onPressed: onPairDevice,
          )
        else
          TextButton.icon(
            icon: const Icon(Icons.phonelink_setup_rounded, size: 16),
            label: const Text('Pair Device'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.accent,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            onPressed: onPairDevice,
          ),
        const SizedBox(width: 4),
        if (compact)
          IconButton(
            tooltip: 'Direct IP Connect',
            icon: const Icon(Icons.add_link_rounded, size: 20),
            splashRadius: 20,
            onPressed: onDirectIp,
          )
        else
          TextButton.icon(
            icon: const Icon(Icons.add_link_rounded, size: 16),
            label: const Text('Direct IP'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            onPressed: onDirectIp,
          ),
        const SizedBox(width: 6),
        Container(width: 1, height: 18, color: AppColors.border),
        const SizedBox(width: 6),
        IconButton(
          tooltip: 'Features Showcase',
          icon: const Icon(
            Icons.auto_awesome_rounded,
            size: 19,
            color: AppColors.accent,
          ),
          splashRadius: 20,
          onPressed: onShowcase,
        ),
        const SizedBox(width: 2),
        IconButton(
          tooltip: 'User Guide & Shortcuts',
          icon: const Icon(
            Icons.menu_book_rounded,
            size: 19,
            color: AppColors.textSecondary,
          ),
          splashRadius: 20,
          onPressed: onUserGuide,
        ),
        const SizedBox(width: 2),
        IconButton(
          tooltip: 'Rescan Network',
          icon: const Icon(
            Icons.refresh_rounded,
            size: 20,
            color: AppColors.textPrimary,
          ),
          splashRadius: 20,
          onPressed: onRescan,
        ),
        const SizedBox(width: 12),
      ],
    );
  }
}
