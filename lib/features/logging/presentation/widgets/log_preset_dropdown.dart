import 'package:flutter/material.dart';
import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/features/logging/domain/entities/log_filter_criteria.dart';
import 'package:desk_droid/features/logging/domain/entities/log_filter_preset.dart';

/// Dropdown selector offering quick activation of predefined filter presets.
class LogPresetDropdown extends StatelessWidget {
  const LogPresetDropdown({
    super.key,
    required this.currentFilter,
    required this.onPresetSelected,
    this.presets,
  });

  final LogFilterCriteria currentFilter;
  final ValueChanged<LogFilterPreset> onPresetSelected;
  final List<LogFilterPreset>? presets;

  @override
  Widget build(BuildContext context) {
    final list = presets ?? LogFilterPreset.defaultPresets;

    return PopupMenuButton<LogFilterPreset>(
      tooltip: 'Quick Filter Presets',
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tune_rounded, size: 13, color: AppColors.accent),
            SizedBox(width: 4),
            Text(
              'Presets',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.accent,
              ),
            ),
            SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 16,
              color: AppColors.accent,
            ),
          ],
        ),
      ),
      padding: EdgeInsets.zero,
      color: AppColors.surfaceElevated,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.border),
      ),
      constraints: const BoxConstraints(maxHeight: 320, minWidth: 220),
      onSelected: onPresetSelected,
      itemBuilder: (context) {
        return list.map((preset) {
          final isSelected = currentFilter == preset.criteria;

          return PopupMenuItem<LogFilterPreset>(
            value: preset,
            height: 36,
            child: Row(
              children: [
                if (preset.icon != null) ...[
                  Icon(
                    preset.icon,
                    size: 16,
                    color: isSelected
                        ? AppColors.accent
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  preset.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.accent
                        : AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (isSelected)
                  const Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: AppColors.accent,
                  ),
              ],
            ),
          );
        }).toList();
      },
    );
  }
}
