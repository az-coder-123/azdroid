import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:wifi_desk/core/theme/app_colors.dart';
import 'package:wifi_desk/core/theme/app_typography.dart';

/// Drop target zone allowing drag-and-drop or file picker selection of an APK package.
class ApkPickerDropZone extends StatelessWidget {
  const ApkPickerDropZone({
    super.key,
    required this.onApkSelected,
    required this.onBrowseTapped,
  });

  final ValueChanged<String> onApkSelected;
  final VoidCallback onBrowseTapped;

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragDone: (detail) {
        final path = detail.files.firstOrNull?.path;
        if (path != null && path.toLowerCase().endsWith('.apk')) {
          onApkSelected(path);
        }
      },
      child: Container(
        height: 240,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.file_upload_outlined,
                  color: AppColors.accentLight,
                  size: 36,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Drag and Drop APK Package Here',
                style: AppTypography.subtitle.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Or browse your computer to select an Android .apk package',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: onBrowseTapped,
                icon: const Icon(Icons.folder_open_rounded, size: 16),
                label: const Text('Browse APK File'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
