import 'package:flutter/material.dart';
import 'package:wifi_desk/core/theme/app_colors.dart';
import 'package:wifi_desk/features/guide/presentation/widgets/user_guide_dialog.dart';
import 'package:wifi_desk/features/showcase/data/app_features_catalog.dart';
import 'package:wifi_desk/features/showcase/domain/entities/app_feature_item.dart';
import 'package:wifi_desk/features/showcase/presentation/widgets/feature_card.dart';
import 'package:wifi_desk/features/showcase/presentation/widgets/feature_category_bar.dart';
import 'package:wifi_desk/features/showcase/presentation/widgets/feature_showcase_header.dart';

/// Modal dialog presenting a modern, categorized showcase of all WifiDesk features.
class FeatureShowcaseDialog extends StatefulWidget {
  const FeatureShowcaseDialog({super.key});

  /// Displays the feature showcase modal dialog.
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const FeatureShowcaseDialog(),
    );
  }

  @override
  State<FeatureShowcaseDialog> createState() => _FeatureShowcaseDialogState();
}

class _FeatureShowcaseDialogState extends State<FeatureShowcaseDialog> {
  FeatureCategory _selectedCategory = FeatureCategory.all;
  String _searchQuery = '';

  List<AppFeatureItem> get _filteredFeatures {
    return AppFeaturesCatalog.allFeatures.where((f) {
      if (_selectedCategory != FeatureCategory.all &&
          f.category != _selectedCategory) {
        return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase().trim();
        final matchTitle = f.title.toLowerCase().contains(q);
        final matchSub = f.subtitle.toLowerCase().contains(q);
        final matchHighlights = f.highlights.any(
          (h) => h.toLowerCase().contains(q),
        );
        final matchBadge = f.badgeText.toLowerCase().contains(q);
        return matchTitle || matchSub || matchHighlights || matchBadge;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final dialogWidth = (size.width * 0.92).clamp(360.0, 960.0);
    final dialogHeight = (size.height * 0.88).clamp(380.0, 680.0);
    final isTwoColumns = dialogWidth >= 680;
    final isCompact = dialogWidth < 540;

    final filtered = _filteredFeatures;

    return Dialog(
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: const BorderSide(color: AppColors.border),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: dialogHeight,
          minWidth: 340,
          minHeight: 340,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.0),
          child: Column(
            children: [
              FeatureShowcaseHeader(
                searchQuery: _searchQuery,
                onSearchChanged: (val) => setState(() => _searchQuery = val),
                isCompact: isCompact,
                onClose: () => Navigator.of(context).pop(),
              ),
              FeatureCategoryBar(
                selectedCategory: _selectedCategory,
                onSelectCategory: (cat) =>
                    setState(() => _selectedCategory = cat),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmptyState()
                    : _buildList(filtered, isTwoColumns),
              ),
              _buildFooter(context, filtered.length, isCompact),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<AppFeatureItem> items, bool isTwoColumns) {
    if (isTwoColumns) {
      final rowCount = (items.length + 1) ~/ 2;
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const ClampingScrollPhysics(),
        itemCount: rowCount,
        itemBuilder: (context, rowIndex) {
          final firstIndex = rowIndex * 2;
          final secondIndex = firstIndex + 1;
          final hasSecond = secondIndex < items.length;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: FeatureCard(feature: items[firstIndex])),
                const SizedBox(width: 12),
                Expanded(
                  child: hasSecond
                      ? FeatureCard(feature: items[secondIndex])
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          );
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const ClampingScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: FeatureCard(feature: items[index]),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 40,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 10),
          const Text(
            'No matching features found',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, int count, bool isCompact) {
    final countText = Text(
      'Showing $count of ${AppFeaturesCatalog.allFeatures.length} features',
      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
    );

    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton.icon(
          icon: const Icon(Icons.menu_book_rounded, size: 14),
          label: const Text('Open User Guide', style: TextStyle(fontSize: 12)),
          onPressed: () {
            Navigator.of(context).pop();
            UserGuideDialog.show(context);
          },
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Got it', style: TextStyle(fontSize: 12)),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: isCompact
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [countText, const SizedBox(height: 6), actions],
            )
          : Row(children: [countText, const Spacer(), actions]),
    );
  }
}
