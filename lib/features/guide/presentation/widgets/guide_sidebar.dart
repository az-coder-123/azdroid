import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/core/theme/app_motion.dart';
import 'package:desk_droid/features/guide/domain/models/guide_category.dart';
import 'package:flutter/material.dart';

/// Navigation sidebar for the user guide dialog, rendering category tabs and platform footer.
class GuideSidebar extends StatelessWidget {
  const GuideSidebar({
    super.key,
    required this.categories,
    required this.selectedIndex,
    required this.onSelectCategory,
    this.isCompact = false,
  });

  final List<GuideCategory> categories;
  final int selectedIndex;
  final ValueChanged<int> onSelectCategory;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isCompact ? 58 : 220,
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(right: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = selectedIndex == index;
                return InkWell(
                  onTap: () => onSelectCategory(index),
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: AppMotion.fast,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.accent : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: isCompact
                        ? Center(
                            child: Tooltip(
                              message: cat.title,
                              child: Icon(
                                cat.icon,
                                size: 18,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          )
                        : Row(
                            children: [
                              Icon(
                                cat.icon,
                                size: 18,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  cat.title,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.borderSubtle)),
            ),
            child: isCompact
                ? const Center(
                    child: Icon(
                      Icons.apple_rounded,
                      size: 14,
                      color: AppColors.textTertiary,
                    ),
                  )
                : const Row(
                    children: [
                      Icon(
                        Icons.apple_rounded,
                        size: 14,
                        color: AppColors.textTertiary,
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Azdroid • macOS Client',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textTertiary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
