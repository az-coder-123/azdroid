import 'package:flutter/material.dart';
import 'package:wifi_desk/core/theme/app_colors.dart';
import 'package:wifi_desk/features/logging/presentation/widgets/log_tag_dropdown_menu.dart';

/// Dropdown menu button displaying all active process IDs (PIDs), their primary module names, and line counts.
class LogPidDropdownMenu extends StatelessWidget {
  const LogPidDropdownMenu({
    super.key,
    required this.selectedPid,
    required this.pidCounts,
    this.pidPrimaryTags = const {},
    required this.onPidSelected,
    required this.onClearPid,
  });

  final int? selectedPid;
  final Map<int, int> pidCounts;
  final Map<int, String> pidPrimaryTags;
  final ValueChanged<int> onPidSelected;
  final VoidCallback onClearPid;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      tooltip: 'Select active Process ID (PID)',
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
        if (val == -1) {
          onClearPid();
        } else {
          onPidSelected(val);
        }
      },
      itemBuilder: (context) {
        if (pidCounts.isEmpty) {
          return const [
            PopupMenuItem<int>(
              enabled: false,
              value: -1,
              height: 36,
              child: Text(
                'No processes detected in log yet',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          ];
        }

        final items = <PopupMenuEntry<int>>[
          PopupMenuItem<int>(
            value: -1,
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
                  'All PIDs / Reset',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
                const Spacer(),
                Text(
                  '${pidCounts.length} PIDs',
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

        for (final entry in pidCounts.entries) {
          final isSelected = selectedPid == entry.key;
          final primaryTag = pidPrimaryTags[entry.key] ?? '';

          items.add(
            PopupMenuItem<int>(
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
                  Text(
                    '${entry.key}',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected
                          ? AppColors.accent
                          : AppColors.textPrimary,
                    ),
                  ),
                  if (primaryTag.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        primaryTag,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ] else
                    const Spacer(),
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
