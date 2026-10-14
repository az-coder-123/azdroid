import 'package:flutter/material.dart';
import 'package:wifi_desk/core/theme/app_colors.dart';
import 'package:wifi_desk/core/theme/app_typography.dart';
import 'package:wifi_desk/features/apk_installer/domain/entities/apk_info_entity.dart';

/// Card presenting inspected APK metadata (app name, package, version, SDK, size).
class ApkInfoCard extends StatelessWidget {
  const ApkInfoCard({super.key, required this.info, this.onChangeApk});

  final ApkInfoEntity info;
  final VoidCallback? onChangeApk;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildAppIcon(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.displayName,
                      style: AppTypography.title.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      info.packageName ?? info.fileName,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (onChangeApk != null)
                TextButton.icon(
                  onPressed: onChangeApk,
                  icon: const Icon(Icons.folder_open_rounded, size: 16),
                  label: const Text('Change'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.accentLight,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.borderSubtle),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildTag(
                icon: Icons.sell_outlined,
                label: info.versionDisplay,
                color: AppColors.accentLight,
              ),
              _buildTag(
                icon: Icons.data_usage_rounded,
                label: info.formattedSize,
                color: AppColors.statusInfo,
              ),
              _buildTag(
                icon: Icons.android_rounded,
                label: info.sdkDisplay,
                color: AppColors.statusSuccess,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppIcon() {
    if (info.iconBytes != null && info.iconBytes!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10.0),
        child: Image.memory(
          info.iconBytes!,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(),
        ),
      );
    }
    return _buildFallbackIcon();
  }

  Widget _buildFallbackIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: const Icon(
        Icons.android_rounded,
        color: AppColors.accentLight,
        size: 28,
      ),
    );
  }

  Widget _buildTag({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
