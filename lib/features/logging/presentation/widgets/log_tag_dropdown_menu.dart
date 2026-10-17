import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Dropdown menu button displaying all active Android log modules and their line counts.
class LogTagDropdownMenu extends StatelessWidget {
  const LogTagDropdownMenu({
    super.key,
    required this.selectedTag,
    required this.tagCounts,
    required this.onTagSelected,
    required this.onClearTag,
  });

  final String selectedTag;
  final Map<String, int> tagCounts;
  final ValueChanged<String> onTagSelected;
  final VoidCallback onClearTag;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Select active module/tag',
      icon: const Icon(
        Icons.arrow_drop_down_rounded,
        size: 20,
        color: AppColors.textSecondary,
      ),
      padding: EdgeInsets.zero,
      color: AppColors.surfaceElevated,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.border),
      ),
      constraints: const BoxConstraints(maxHeight: 320, minWidth: 260),
      onSelected: (val) {
        if (val.isEmpty) {
          onClearTag();
        } else {
          onTagSelected(val);
        }
      },
      itemBuilder: (context) {
        if (tagCounts.isEmpty) {
          return const [
            PopupMenuItem<String>(
              enabled: false,
              height: 36,
              child: Text(
                'No modules detected in log yet',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          ];
        }

        final items = <PopupMenuEntry<String>>[
          PopupMenuItem<String>(
            value: '',
            height: 32,
            child: Row(
              children: [
                const Icon(
                  Icons.clear_all_rounded,
                  size: 16,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 8),
                const Text(
                  'All Tags / Reset',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
                const Spacer(),
                Text(
                  '${tagCounts.length} modules',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const PopupMenuDivider(height: 1),
        ];

        for (final entry in tagCounts.entries) {
          final isSelected = selectedTag.trim() == entry.key;
          items.add(
            PopupMenuItem<String>(
              value: entry.key,
              height: 32,
              child: Row(
                children: [
                  if (isSelected)
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: AppColors.accent,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      entry.key,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isSelected
                            ? AppColors.accent
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  LogTagCountBadge(count: entry.value),
                ],
              ),
            ),
          );
        }

        return items;
      },
    );
  }
}

/// Small pill badge displaying the occurrence count of a log module.
class LogTagCountBadge extends StatelessWidget {
  const LogTagCountBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          fontSize: 10,
          color: AppColors.textSecondary,
          fontFamily: 'monospace',
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
