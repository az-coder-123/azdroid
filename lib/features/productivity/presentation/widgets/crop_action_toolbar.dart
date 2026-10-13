import 'package:flutter/material.dart';
import 'package:wifi_desk/core/theme/app_colors.dart';
import 'package:wifi_desk/features/productivity/domain/entities/screenshot_destination.dart';

/// Elegant floating glassmorphic toolbar presented after a marquee area selection
/// allowing the user to choose between copying to clipboard, saving to file, or both.
class CropActionToolbar extends StatelessWidget {
  const CropActionToolbar({
    super.key,
    required this.onSelect,
    required this.onCancel,
  });

  final ValueChanged<ScreenshotDestination> onSelect;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(22.0),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Clipboard only
          _buildActionButton(
            icon: Icons.copy_rounded,
            label: 'Clipboard',
            tooltip: 'Copy to Clipboard only (C)',
            onTap: () => onSelect(ScreenshotDestination.clipboard),
          ),

          _buildDivider(),

          // File only
          _buildActionButton(
            icon: Icons.download_rounded,
            label: 'Save File',
            tooltip: 'Save to ~/Downloads (S)',
            onTap: () => onSelect(ScreenshotDestination.file),
          ),

          _buildDivider(),

          // Both (Highlighted primary option)
          _buildPrimaryButton(
            icon: Icons.done_all_rounded,
            label: 'Both',
            tooltip: 'Save File & Copy to Clipboard (Enter)',
            onTap: () => onSelect(ScreenshotDestination.both),
          ),

          _buildDivider(),

          // Cancel
          Tooltip(
            message: 'Cancel selection (Esc)',
            child: InkWell(
              onTap: onCancel,
              borderRadius: BorderRadius.circular(16.0),
              hoverColor: AppColors.surface,
              child: const Padding(
                padding: EdgeInsets.all(6.0),
                child: Icon(
                  Icons.close_rounded,
                  size: 16.0,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1.0,
      height: 16.0,
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      color: AppColors.borderSubtle,
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.0),
        hoverColor: AppColors.surface,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14.0, color: AppColors.textPrimary),
              const SizedBox(width: 5.0),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                  fontFamily: 'SF Pro Text',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required IconData icon,
    required String label,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14.0, color: AppColors.accentLight),
              const SizedBox(width: 5.0),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accentLight,
                  fontFamily: 'SF Pro Text',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
