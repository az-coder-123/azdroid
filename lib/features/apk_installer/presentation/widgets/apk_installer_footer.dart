import 'package:flutter/material.dart';
import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/features/apk_installer/presentation/cubit/apk_installer_state.dart';

/// Modal dialog action footer for [ApkInstallerDialog].
class ApkInstallerFooter extends StatelessWidget {
  const ApkInstallerFooter({
    super.key,
    required this.state,
    required this.onReset,
    required this.onInstall,
    required this.onClose,
  });

  final ApkInstallerState state;
  final VoidCallback onReset;
  final VoidCallback onInstall;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
      color: AppColors.surfaceElevated,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (state is ApkInstallerSuccess)
            TextButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Install Another APK'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accentLight,
              ),
            )
          else
            const SizedBox.shrink(),
          Row(
            children: [
              OutlinedButton(
                onPressed: onClose,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Text(state is ApkInstallerSuccess ? 'Done' : 'Cancel'),
              ),
              if (state is ApkInstallerReady) ...[
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: onInstall,
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: const Text('Install to Device'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
