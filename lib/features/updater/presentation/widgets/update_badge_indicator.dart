import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/features/updater/presentation/cubit/updater_cubit.dart';
import 'package:desk_droid/features/updater/presentation/cubit/updater_state.dart';
import 'package:desk_droid/features/updater/presentation/widgets/update_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Toolbar indicator button that shows an update badge when a newer release is discovered.
class UpdateBadgeIndicator extends StatelessWidget {
  const UpdateBadgeIndicator({super.key});

  static const double _iconSize = 19;
  static const double _dotSize = 8;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UpdaterCubit, UpdaterState>(
      listener: (context, state) {
        if (state is UpdaterUpToDate) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Azdroid is up to date (v${state.currentVersion}).',
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        } else if (state is UpdaterFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      builder: (context, state) {
        final (tooltip, isAvailable, isChecking) = switch (state) {
          UpdaterAvailable(:final updateInfo) => (
            'Update available: ${updateInfo.latestVersion}',
            true,
            false,
          ),
          UpdaterChecking() => ('Checking for updates…', false, true),
          UpdaterUpToDate(:final currentVersion) => (
            'Up to date ($currentVersion). Click to check again.',
            false,
            false,
          ),
          UpdaterFailure() => (
            'Update check unavailable. Click to retry.',
            false,
            false,
          ),
          UpdaterInitial() => ('Check for software updates', false, false),
        };

        Widget iconWidget = const Icon(
          Icons.system_update_alt_rounded,
          size: _iconSize,
          color: AppColors.textSecondary,
        );

        if (isChecking) {
          iconWidget = const SizedBox(
            width: _iconSize,
            height: _iconSize,
            child: Padding(
              padding: EdgeInsets.all(3.0),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.accent,
              ),
            ),
          );
        } else if (isAvailable) {
          iconWidget = const Badge(
            smallSize: _dotSize,
            backgroundColor: AppColors.statusSuccess,
            child: Icon(
              Icons.system_update_rounded,
              size: _iconSize,
              color: AppColors.accent,
            ),
          );
        }

        return IconButton(
          tooltip: tooltip,
          splashRadius: 20,
          onPressed: () {
            if (state is UpdaterAvailable) {
              UpdateDialog.show(context, state.updateInfo);
            } else if (!isChecking) {
              context.read<UpdaterCubit>().checkForUpdates(force: true);
            }
          },
          icon: iconWidget,
        );
      },
    );
  }
}
