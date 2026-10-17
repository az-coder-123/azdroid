import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// Single item displaying Apple keyboard shortcut keys (keycap badges) and their description.
class GuideShortcutItem extends StatelessWidget {
  const GuideShortcutItem({
    super.key,
    required this.keys,
    required this.description,
  });

  final List<String> keys;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Wrap(
            spacing: 4,
            children: keys
                .map(
                  (k) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      k,
                      style: const TextStyle(
                        fontFamily: 'SF Mono',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(description, style: AppTypography.body)),
        ],
      ),
    );
  }
}
