import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/features/updater/presentation/cubit/updater_cubit.dart';
import 'package:desk_droid/features/updater/presentation/cubit/updater_state.dart';
import 'package:desk_droid/features/updater/presentation/widgets/update_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Contextual, non-blocking notification banner shown when an update is available.
class UpdateBanner extends StatelessWidget {
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UpdaterCubit, UpdaterState>(
      builder: (context, state) {
        if (state is! UpdaterAvailable || state.isBannerDismissed) {
          return const SizedBox.shrink();
        }

        final info = state.updateInfo;

        return Container(
          margin: const EdgeInsets.fromLTRB(24, 12, 24, 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 16,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Azdroid ${info.latestVersion} is available!',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'A newer version is ready for installation. Click to view release details.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary.withValues(alpha: 0.9),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                onPressed: () => UpdateDialog.show(context, info),
                child: const Text('View Details'),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Dismiss',
                icon: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
                splashRadius: 16,
                onPressed: () => context.read<UpdaterCubit>().dismissBanner(),
              ),
            ],
          ),
        );
      },
    );
  }
}
