import 'package:desk_droid/core/platform/shortcuts/shortcut_scheme.dart';
import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/core/theme/app_motion.dart';
import 'package:desk_droid/features/showcase/data/app_features_catalog.dart';
import 'package:desk_droid/features/showcase/domain/entities/app_feature_item.dart';
import 'package:flutter/material.dart';

/// Horizontal category selector bar rendering macOS-native styled pill filters
/// with interactive counts.
class FeatureCategoryBar extends StatelessWidget {
  const FeatureCategoryBar({
    super.key,
    required this.selectedCategory,
    required this.onSelectCategory,
    this.categoryCounts,
  });

  final FeatureCategory selectedCategory;
  final ValueChanged<FeatureCategory> onSelectCategory;
  final Map<FeatureCategory, int>? categoryCounts;

  int _getCount(FeatureCategory cat) {
    if (categoryCounts != null && categoryCounts!.containsKey(cat)) {
      return categoryCounts![cat]!;
    }
    if (cat == FeatureCategory.all) {
      return AppFeaturesCatalog.allFeatures.length;
    }
    return AppFeaturesCatalog.allFeatures
        .where((f) => f.category == cat)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: FeatureCategory.values.map((cat) {
          final isSelected = cat == selectedCategory;
          final count = _getCount(cat);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => onSelectCategory(cat),
              child: AnimatedContainer(
                duration: AppMotion.medium,
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accent.withValues(alpha: 0.18)
                      : AppColors.surfaceElevated.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.accent
                        : AppColors.borderSubtle,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      cat == FeatureCategory.shortcuts
                          ? context.shortcuts.shortcutIcon
                          : cat.icon,
                      size: 14,
                      color: isSelected
                          ? AppColors.accent
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      cat.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isSelected
                            ? AppColors.accent
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Counter pill badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accent.withValues(alpha: 0.25)
                            : AppColors.surface.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.accent.withValues(alpha: 0.45)
                              : AppColors.borderSubtle.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppColors.accent
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
