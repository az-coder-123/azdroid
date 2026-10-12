import 'package:flutter/material.dart';
import 'package:wifi_desk/core/theme/app_colors.dart';

/// Responsive actions toolbar rendered in the DiscoveryPage AppBar.
class DiscoveryAppBarActions extends StatelessWidget {
  const DiscoveryAppBarActions({
    super.key,
    required this.onPairDevice,
    required this.onDirectIp,
    required this.onUserGuide,
    required this.onRescan,
  });

  final VoidCallback onPairDevice;
  final VoidCallback onDirectIp;
  final VoidCallback onUserGuide;
  final VoidCallback onRescan;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 620;

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
            onPressed: onPairDevice,
          )
        else
          TextButton.icon(
            icon: const Icon(Icons.phonelink_setup_rounded, size: 16),
            label: const Text('Pair Device'),
            style: TextButton.styleFrom(foregroundColor: AppColors.accent),
            onPressed: onPairDevice,
          ),
        const SizedBox(width: 4),
        if (compact)
          IconButton(
            tooltip: 'Direct IP',
            icon: const Icon(Icons.add_link_rounded, size: 20),
            onPressed: onDirectIp,
          )
        else
          TextButton.icon(
            icon: const Icon(Icons.add_link_rounded, size: 16),
            label: const Text('Direct IP'),
            style: TextButton.styleFrom(foregroundColor: AppColors.textPrimary),
            onPressed: onDirectIp,
          ),
        const SizedBox(width: 4),
        IconButton(
          tooltip: 'User Guide',
          icon: const Icon(Icons.menu_book_rounded, size: 20),
          onPressed: onUserGuide,
        ),
        const SizedBox(width: 4),
        IconButton(
          tooltip: 'Rescan Network',
          icon: const Icon(Icons.refresh_rounded),
          onPressed: onRescan,
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
