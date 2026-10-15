import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/features/productivity/presentation/cubit/file_transfer_cubit.dart';
import 'package:desk_droid/features/productivity/presentation/cubit/file_transfer_state.dart';

/// Floating toast banner rendering current transfer progress, success, or error alerts.
class TransferStatusBanner extends StatelessWidget {
  const TransferStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FileTransferCubit, FileTransferState>(
      builder: (context, state) {
        if (state is FileTransferInitial) {
          return const SizedBox.shrink();
        }

        if (state is FileTransferActive) {
          final transfer = state.currentTransfer;
          final sizeLabel = transfer.formattedSize.isNotEmpty
              ? ' (${transfer.formattedSize})'
              : '';
          return _buildBanner(
            icon: transfer.isApk
                ? Icons.android_rounded
                : Icons.upload_file_rounded,
            iconColor: AppColors.accent,
            title: transfer.isApk
                ? 'Installing APK: ${transfer.fileName}$sizeLabel'
                : 'Transferring: ${transfer.fileName}$sizeLabel',
            subtitle: 'Item ${state.completedCount + 1} of ${state.totalCount}',
            showProgress: true,
          );
        }

        if (state is FileTransferSuccess) {
          final transfer = state.completedTransfer;
          final sizeLabel = transfer.formattedSize.isNotEmpty
              ? ' • ${transfer.formattedSize}'
              : '';
          return _buildBanner(
            icon: Icons.check_circle_outline_rounded,
            iconColor: AppColors.statusSuccess,
            title: transfer.isApk
                ? 'APK Successfully Installed'
                : 'File Transfer Complete',
            subtitle: transfer.isApk
                ? '${transfer.fileName}$sizeLabel'
                : 'Saved to /sdcard/Download/${transfer.fileName}$sizeLabel',
            onDismiss: () => context.read<FileTransferCubit>().reset(),
          );
        }

        if (state is FileTransferFailure) {
          return _buildBanner(
            icon: Icons.error_outline_rounded,
            iconColor: AppColors.statusError,
            title: 'Transfer Failed',
            subtitle: state.errorMessage,
            onDismiss: () => context.read<FileTransferCubit>().reset(),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildBanner({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    bool showProgress = false,
    VoidCallback? onDismiss,
  }) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 360),
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: AppColors.textTertiary,
                  ),
                  splashRadius: 14,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onDismiss,
                ),
            ],
          ),
          if (showProgress) ...[
            const SizedBox(height: 8),
            const ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(2)),
              child: LinearProgressIndicator(
                minHeight: 3,
                backgroundColor: AppColors.surface,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
