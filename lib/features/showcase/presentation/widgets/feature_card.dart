import 'package:desk_droid/core/platform/shortcuts/shortcut_scheme.dart';
import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/features/showcase/domain/entities/app_feature_item.dart';
import 'package:flutter/material.dart';

/// Card widget rendering an individual feature with icon, badge, highlights, and pro tips.
class FeatureCard extends StatelessWidget {
  const FeatureCard({super.key, required this.feature});

  final AppFeatureItem feature;

  @override
  Widget build(BuildContext context) {
    final shortcuts = context.shortcuts;
    final title = shortcuts.adapt(feature.title);
    final subtitle = shortcuts.adapt(feature.subtitle);
    final badgeText = shortcuts.adapt(feature.badgeText);
    final highlights = feature.highlights.map(shortcuts.adapt).toList();
    final proTip = shortcuts.adapt(feature.proTip);
    final cardIcon =
        (feature.id == 'shortcuts_master' && !shortcuts.usesMetaKey)
        ? Icons.keyboard_rounded
        : feature.icon;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon + Title + Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      feature.badgeColor.withValues(alpha: 0.25),
                      feature.badgeColor.withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: feature.badgeColor.withValues(alpha: 0.35),
                  ),
                ),
                child: Icon(cardIcon, size: 20, color: feature.badgeColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Shrinks with an ellipsis on narrow cards, so a
                        // long badge never overflows the title row.
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: feature.badgeColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: feature.badgeColor.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Text(
                              badgeText,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: feature.badgeColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.borderSubtle),
          const SizedBox(height: 10),

          // Bullet points
          ...highlights.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4, right: 8),
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 13,
                      color: AppColors.accent,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Pro tip box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.borderSubtle.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 14,
                  color: AppColors.statusWarning,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    proTip,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                      height: 1.3,
                    ),
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
