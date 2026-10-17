import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/core/theme/app_typography.dart';
import 'package:desk_droid/features/apk_installer/domain/entities/apk_info_entity.dart';
import 'package:desk_droid/features/apk_installer/domain/entities/apk_install_result.dart';
import 'package:flutter/material.dart';

/// Card displaying post-installation outcome (success with launch action, or failure with diagnosis).
class ApkInstallResultCard extends StatelessWidget {
  const ApkInstallResultCard({
    super.key,
    required this.apkInfo,
    required this.result,
    this.appLaunched = false,
    this.isUninstallingOld = false,
    this.onLaunchApp,
    this.onRetry,
    this.onUninstallAndRetry,
  });

  final ApkInfoEntity apkInfo;
  final ApkInstallResult result;
  final bool appLaunched;
  final bool isUninstallingOld;
  final VoidCallback? onLaunchApp;
  final VoidCallback? onRetry;
  final VoidCallback? onUninstallAndRetry;

  @override
  Widget build(BuildContext context) {
    return result.success ? _buildSuccess(context) : _buildFailure(context);
  }

  Widget _buildSuccess(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: AppColors.statusSuccess.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.statusSuccess.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppColors.statusSuccess,
              size: 40,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Installation Successful!',
            style: AppTypography.title.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${apkInfo.displayName} is now ready on your Android device.',
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          if (onLaunchApp != null)
            ElevatedButton.icon(
              onPressed: appLaunched ? null : onLaunchApp,
              icon: Icon(
                appLaunched
                    ? Icons.done_all_rounded
                    : Icons.rocket_launch_rounded,
                size: 18,
              ),
              label: Text(
                appLaunched ? 'App Launched' : 'Launch App on Device',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: appLaunched
                    ? AppColors.surfaceElevated
                    : AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFailure(BuildContext context) {
    final canUninstall =
        result.errorCode == 'INSTALL_FAILED_UPDATE_INCOMPATIBLE';

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: AppColors.statusError.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.statusError.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.statusError,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.errorTitle ?? 'Installation Failed',
                      style: AppTypography.subtitle.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.statusError,
                      ),
                    ),
                    if (result.errorCode != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        result.errorCode!,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (result.errorDescription != null) ...[
            const SizedBox(height: 12),
            Text(
              result.errorDescription!,
              style: AppTypography.body.copyWith(color: AppColors.textPrimary),
            ),
          ],
          if (result.suggestedAction != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 16,
                    color: AppColors.statusWarning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      result.suggestedAction!,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (canUninstall && onUninstallAndRetry != null) ...[
                OutlinedButton.icon(
                  onPressed: isUninstallingOld ? null : onUninstallAndRetry,
                  icon: isUninstallingOld
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.statusError,
                          ),
                        )
                      : const Icon(Icons.delete_sweep_rounded, size: 16),
                  label: Text(
                    isUninstallingOld
                        ? 'Uninstalling...'
                        : 'Uninstall Old & Retry',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.statusError,
                    side: const BorderSide(color: AppColors.statusError),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              if (onRetry != null)
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Retry Install'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
