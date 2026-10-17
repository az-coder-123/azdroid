import 'package:desk_droid/core/platform/shortcuts/shortcut_scheme.dart';
import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/features/productivity/presentation/cubit/screen_recording_cubit.dart';
import 'package:desk_droid/features/productivity/presentation/cubit/screen_recording_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Toolbar action button for toggling screen recording, preparation, and countdowns.
class ScreenRecordButton extends StatelessWidget {
  const ScreenRecordButton({required this.deviceSerial, super.key});

  final String deviceSerial;

  @override
  Widget build(BuildContext context) {
    final keys = context.shortcuts;
    return BlocBuilder<ScreenRecordingCubit, ScreenRecordingState>(
      builder: (context, state) {
        if (state is ScreenRecordingFinalizing) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.accent,
              ),
            ),
          );
        }

        final isRecording = state is ScreenRecordingActive;
        final isPreparing = state is ScreenRecordingPreparing;
        final isCountdown = state is ScreenRecordingCountdown;

        final IconData icon;
        final String tooltip;
        final Color? color;
        final VoidCallback onPressed;

        if (isRecording) {
          icon = Icons.stop_circle_rounded;
          tooltip = 'Stop Recording (REC)';
          color = AppColors.statusError;
          onPressed = () =>
              context.read<ScreenRecordingCubit>().stopRecording();
        } else if (isCountdown || isPreparing) {
          icon = isCountdown
              ? Icons.hourglass_top_rounded
              : Icons.videocam_rounded;
          tooltip = isCountdown
              ? 'Counting down (Cancel)'
              : 'Cancel Recording Setup';
          color = AppColors.statusError;
          onPressed = () =>
              context.read<ScreenRecordingCubit>().cancelPreparation();
        } else {
          icon = Icons.videocam_outlined;
          tooltip = 'Record Screen (${keys.label('R', shift: true)})';
          color = null;
          onPressed = () => context
              .read<ScreenRecordingCubit>()
              .prepareRecording(deviceSerial);
        }

        return Tooltip(
          message: tooltip,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(8.0),
            hoverColor: AppColors.surfaceElevated,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                icon,
                size: 20.0,
                color: color ?? AppColors.textPrimary,
              ),
            ),
          ),
        );
      },
    );
  }
}
