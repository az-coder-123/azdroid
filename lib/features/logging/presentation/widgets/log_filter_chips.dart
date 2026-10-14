import 'package:flutter/material.dart';
import 'package:wifi_desk/core/theme/app_colors.dart';

/// Interactive chip for selecting log severity level filters.
class LogFilterChip extends StatelessWidget {
  const LogFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.22) : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(6.0),
          border: Border.all(
            color: isSelected ? color : AppColors.borderSubtle,
            width: isSelected ? 1.0 : 0.75,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.0,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? color : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Compact toggle button for search modifier options (e.g. Regex, Case-sensitivity).
class LogOptionToggle extends StatelessWidget {
  const LogOptionToggle({
    super.key,
    required this.label,
    required this.tooltip,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final String tooltip;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: isActive ? AppColors.accent.withValues(alpha: 0.25) : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(6.0),
            border: Border.all(color: isActive ? AppColors.accent : AppColors.borderSubtle),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.0,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              color: isActive ? AppColors.accent : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
