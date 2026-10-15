import 'package:flutter/material.dart';
import 'package:wifi_desk/core/theme/app_colors.dart';
import 'package:wifi_desk/core/theme/app_typography.dart';

/// Top header bar for FeatureShowcaseDialog with title, icon, and adaptive search input.
class FeatureShowcaseHeader extends StatelessWidget {
  const FeatureShowcaseHeader({
    super.key,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.isCompact,
    required this.onClose,
  });

  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final bool isCompact;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accent, AppColors.accentLight],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('WifiDesk Features Showcase', style: AppTypography.title),
                if (!isCompact)
                  const Text(
                    'Overview of display mirroring, remote control, and productivity tools',
                    style: AppTypography.caption,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: isCompact ? 110 : 160,
            height: 32,
            child: TextField(
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: isCompact ? 'Search...' : 'Search features...',
                hintStyle: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
                prefixIcon: const Icon(Icons.search_rounded, size: 14),
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                filled: true,
                fillColor: AppColors.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.borderSubtle),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.borderSubtle),
                ),
              ),
              onChanged: onSearchChanged,
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            tooltip: 'Close (Esc)',
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}
