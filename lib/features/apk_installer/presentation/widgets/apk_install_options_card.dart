import 'package:flutter/material.dart';
import 'package:wifi_desk/core/theme/app_colors.dart';
import 'package:wifi_desk/core/theme/app_typography.dart';
import 'package:wifi_desk/features/apk_installer/domain/entities/apk_install_options.dart';

/// Card allowing users to configure installation flags (-r, -g, -t, -d).
class ApkInstallOptionsCard extends StatelessWidget {
  const ApkInstallOptionsCard({
    super.key,
    required this.options,
    required this.onChanged,
    this.enabled = true,
  });

  final ApkInstallOptions options;
  final ValueChanged<ApkInstallOptions> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14.0),
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
              const Icon(
                Icons.tune_rounded,
                size: 16,
                color: AppColors.accentLight,
              ),
              const SizedBox(width: 8),
              Text(
                'Installation Options',
                style: AppTypography.subtitle.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildSwitchRow(
            title: 'Reinstall & Replace Existing App (-r)',
            subtitle: 'Overwrites existing installed app while preserving its app data.',
            value: options.reinstall,
            onChanged: enabled
                ? (v) => onChanged(options.copyWith(reinstall: v))
                : null,
          ),
          const Divider(height: 14, color: AppColors.borderSubtle),
          _buildSwitchRow(
            title: 'Grant All Runtime Permissions (-g)',
            subtitle: 'Automatically grants all declared Android runtime permissions upon install.',
            value: options.grantPermissions,
            onChanged: enabled
                ? (v) => onChanged(options.copyWith(grantPermissions: v))
                : null,
          ),
          const Divider(height: 14, color: AppColors.borderSubtle),
          _buildSwitchRow(
            title: 'Allow Test-Only Packages (-t)',
            subtitle: 'Permits installing APKs built in debug mode with testOnly flag.',
            value: options.allowTestOnly,
            onChanged: enabled
                ? (v) => onChanged(options.copyWith(allowTestOnly: v))
                : null,
          ),
          const Divider(height: 14, color: AppColors.borderSubtle),
          _buildSwitchRow(
            title: 'Allow Version Downgrade (-d)',
            subtitle: 'Allows installing an APK with a lower version code than the installed one.',
            value: options.allowDowngrade,
            warning: options.allowDowngrade
                ? 'Caution: Downgrading may cause app data incompatibility.'
                : null,
            onChanged: enabled
                ? (v) => onChanged(options.copyWith(allowDowngrade: v))
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
    String? warning,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (warning != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 14,
                        color: AppColors.statusWarning,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        warning,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.statusWarning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(
            value: value,
            activeTrackColor: AppColors.accent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
