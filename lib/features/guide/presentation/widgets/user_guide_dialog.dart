import 'package:flutter/material.dart';
import 'package:wifi_desk/core/theme/app_colors.dart';
import 'package:wifi_desk/core/theme/app_typography.dart';
import 'package:wifi_desk/features/guide/domain/models/guide_category.dart';
import 'package:wifi_desk/features/guide/presentation/widgets/guide_sidebar.dart';
import 'package:wifi_desk/features/guide/presentation/widgets/sections/controls_section.dart';
import 'package:wifi_desk/features/guide/presentation/widgets/sections/productivity_section.dart';
import 'package:wifi_desk/features/guide/presentation/widgets/sections/quick_start_section.dart';
import 'package:wifi_desk/features/guide/presentation/widgets/sections/troubleshooting_section.dart';
import 'package:wifi_desk/features/guide/presentation/widgets/sections/xiaomi_setup_section.dart';

/// Modal dialog orchestrator for the WifiDesk user guide, presenting a macOS-native
/// two-column split view with categorized documentation tabs.
class UserGuideDialog extends StatefulWidget {
  const UserGuideDialog({super.key});

  /// Static helper to display the user guide modal dialog.
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const UserGuideDialog(),
    );
  }

  @override
  State<UserGuideDialog> createState() => _UserGuideDialogState();
}

class _UserGuideDialogState extends State<UserGuideDialog> {
  int _selectedCategoryIndex = 0;

  static const List<GuideCategory> _categories = [
    GuideCategory(
      id: 'quick_start',
      title: 'Quick Start & Pairing',
      subtitle: '3 connection methods: QR, USB, Direct IP',
      icon: Icons.rocket_launch_rounded,
    ),
    GuideCategory(
      id: 'xiaomi',
      title: 'Xiaomi / MIUI Setup',
      subtitle: 'Redmi, POCO & touch permission security',
      icon: Icons.phone_android_rounded,
    ),
    GuideCategory(
      id: 'controls',
      title: 'Mouse & Shortcuts',
      subtitle: 'Gestures, navigation keys & Mac shortcuts',
      icon: Icons.mouse_rounded,
    ),
    GuideCategory(
      id: 'productivity',
      title: 'Files & Clipboard',
      subtitle: 'Finder drag-and-drop, APKs & clipboard',
      icon: Icons.folder_copy_rounded,
    ),
    GuideCategory(
      id: 'troubleshooting',
      title: 'Troubleshooting FAQ',
      subtitle: 'Common network errors & solutions',
      icon: Icons.build_circle_rounded,
    ),
  ];

  Widget _buildDetailContent() {
    switch (_selectedCategoryIndex) {
      case 0:
        return const QuickStartSection();
      case 1:
        return const XiaomiSetupSection();
      case 2:
        return const ControlsSection();
      case 3:
        return const ProductivitySection();
      case 4:
        return const TroubleshootingSection();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final dialogWidth = (size.width * 0.9).clamp(320.0, 780.0);
    final dialogHeight = (size.height * 0.85).clamp(360.0, 600.0);
    final isCompact = dialogWidth < 580;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: const BorderSide(color: AppColors.border),
      ),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.0),
          child: Column(
            children: [
              // Top Window Bar with Title & Close Action
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  border: Border(
                    bottom: BorderSide(color: AppColors.borderSubtle),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        color: AppColors.accent,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WifiDesk User Guide',
                            style: AppTypography.title,
                          ),
                          Text(
                            'Complete handbook for wireless mirroring & remote control on macOS',
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      tooltip: 'Close (Esc)',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Split Master-Detail Layout
              Expanded(
                child: Row(
                  children: [
                    GuideSidebar(
                      categories: _categories,
                      selectedIndex: _selectedCategoryIndex,
                      isCompact: isCompact,
                      onSelectCategory: (index) {
                        setState(() => _selectedCategoryIndex = index);
                      },
                    ),
                    Expanded(
                      child: Container(
                        color: AppColors.surface,
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(isCompact ? 16 : 24),
                          child: _buildDetailContent(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
