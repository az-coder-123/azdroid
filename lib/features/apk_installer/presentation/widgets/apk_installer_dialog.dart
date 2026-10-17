import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:desk_droid/core/di/injection.dart';
import 'package:desk_droid/core/services/mac_file_picker_service.dart';
import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/core/theme/app_typography.dart';
import 'package:desk_droid/features/apk_installer/domain/repositories/apk_installer_repository.dart';
import 'package:desk_droid/features/apk_installer/presentation/cubit/apk_installer_cubit.dart';
import 'package:desk_droid/features/apk_installer/presentation/cubit/apk_installer_state.dart';
import 'package:desk_droid/features/apk_installer/presentation/widgets/apk_info_card.dart';
import 'package:desk_droid/features/apk_installer/presentation/widgets/apk_install_options_card.dart';
import 'package:desk_droid/features/apk_installer/presentation/widgets/apk_install_progress_card.dart';
import 'package:desk_droid/features/apk_installer/presentation/widgets/apk_install_result_card.dart';
import 'package:desk_droid/features/apk_installer/presentation/widgets/apk_installer_footer.dart';
import 'package:desk_droid/features/apk_installer/presentation/widgets/apk_picker_drop_zone.dart';

/// Modal dialog providing professional APK inspection, options configuration, and sideloading.
class ApkInstallerDialog extends StatelessWidget {
  const ApkInstallerDialog({super.key});

  /// Displays the [ApkInstallerDialog].
  static Future<void> show(
    BuildContext context, {
    required String deviceSerial,
    String? initialApkPath,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => BlocProvider<ApkInstallerCubit>(
        create: (_) {
          final cubit = ApkInstallerCubit(
            repository: sl<ApkInstallerRepository>(),
            deviceSerial: deviceSerial,
          );
          if (initialApkPath != null) {
            cubit.selectApk(initialApkPath);
          }
          return cubit;
        },
        child: const ApkInstallerDialog(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: const BorderSide(color: AppColors.border),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 640,
          maxHeight: 680,
          minWidth: 460,
          minHeight: 380,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.0),
          child: BlocBuilder<ApkInstallerCubit, ApkInstallerState>(
            builder: (context, state) {
              return Column(
                children: [
                  _buildHeader(context, state),
                  const Divider(height: 1, color: AppColors.border),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20.0),
                      child: _buildBody(context, state),
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  ApkInstallerFooter(
                    state: state,
                    onReset: () => context.read<ApkInstallerCubit>().reset(),
                    onInstall: () =>
                        context.read<ApkInstallerCubit>().install(),
                    onClose: () => Navigator.of(context).pop(),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ApkInstallerState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
      color: AppColors.surfaceElevated,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: const Icon(
              Icons.install_mobile_rounded,
              color: AppColors.accentLight,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Install APK Package',
                  style: AppTypography.title.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Device: ${state.deviceSerial}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.close_rounded,
              size: 20,
              color: AppColors.textSecondary,
            ),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, ApkInstallerState state) {
    if (state is ApkInstallerInitial) {
      return ApkPickerDropZone(
        onApkSelected: (path) =>
            context.read<ApkInstallerCubit>().selectApk(path),
        onBrowseTapped: () => _pickApk(context),
      );
    }

    if (state is ApkInstallerInspecting) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 48.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.accent),
              SizedBox(height: 16),
              Text(
                'Inspecting APK metadata...',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    if (state is ApkInstallerReady) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ApkInfoCard(
            info: state.apkInfo,
            onChangeApk: () => _pickApk(context),
          ),
          const SizedBox(height: 16),
          ApkInstallOptionsCard(
            options: state.options,
            onChanged: (opt) =>
                context.read<ApkInstallerCubit>().updateOptions(opt),
          ),
        ],
      );
    }

    if (state is ApkInstallerInstalling) {
      return Column(
        children: [
          ApkInfoCard(info: state.apkInfo),
          const SizedBox(height: 16),
          ApkInstallProgressCard(statusMessage: state.statusMessage),
        ],
      );
    }

    if (state is ApkInstallerSuccess) {
      return Column(
        children: [
          ApkInfoCard(info: state.apkInfo),
          const SizedBox(height: 16),
          ApkInstallResultCard(
            apkInfo: state.apkInfo,
            result: state.result,
            appLaunched: state.appLaunched,
            onLaunchApp: () => context.read<ApkInstallerCubit>().launchApp(),
          ),
        ],
      );
    }

    if (state is ApkInstallerFailure) {
      return Column(
        children: [
          ApkInfoCard(info: state.apkInfo),
          const SizedBox(height: 16),
          ApkInstallResultCard(
            apkInfo: state.apkInfo,
            result: state.result,
            isUninstallingOld: state.isUninstallingOld,
            onRetry: () => context.read<ApkInstallerCubit>().install(),
            onUninstallAndRetry: () =>
                context.read<ApkInstallerCubit>().uninstallAndRetry(),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _pickApk(BuildContext context) async {
    final picker = sl<MacFilePickerService>();
    final path = await picker.pickApkFile();
    if (path != null && context.mounted) {
      context.read<ApkInstallerCubit>().selectApk(path);
    }
  }
}
