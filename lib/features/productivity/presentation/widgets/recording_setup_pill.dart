import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wifi_desk/core/theme/app_colors.dart';
import 'package:wifi_desk/features/productivity/presentation/cubit/screen_recording_cubit.dart';
import 'package:wifi_desk/features/productivity/presentation/cubit/screen_recording_state.dart';

/// Floating preparation HUD banner enabling user to configure countdown and trigger start.
class RecordingSetupPill extends StatelessWidget {
  const RecordingSetupPill({super.key, required this.state});

  final ScreenRecordingPreparing state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.statusError.withValues(alpha: 0.45),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Camera Indicator Dot
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.statusError,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),

          // Title
          const Text(
            'Record Screen',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'SF Pro Text',
            ),
          ),
          const SizedBox(width: 10),

          // Countdown Toggle Pill
          Tooltip(
            message: state.countdownEnabled
                ? '3-second countdown before recording (Enabled)'
                : 'Record immediately (Countdown disabled)',
            child: InkWell(
              onTap: () =>
                  context.read<ScreenRecordingCubit>().toggleCountdown(),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: state.countdownEnabled
                      ? AppColors.accent.withValues(alpha: 0.22)
                      : AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: state.countdownEnabled
                        ? AppColors.accent.withValues(alpha: 0.6)
                        : AppColors.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 13,
                      color: state.countdownEnabled
                          ? AppColors.accent
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '3s',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: state.countdownEnabled
                            ? AppColors.accent
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Start Button
          ElevatedButton.icon(
            onPressed: () {
              context.read<ScreenRecordingCubit>().startWithCountdown(
                state.deviceSerial,
              );
            },
            icon: const Icon(Icons.fiber_manual_record, size: 12),
            label: const Text(
              'Start',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusError,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: const Size(0, 28),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Cancel Action
          Tooltip(
            message: 'Cancel (Esc)',
            child: IconButton(
              icon: const Icon(Icons.close_rounded, size: 16),
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
              color: AppColors.textSecondary,
              onPressed: () {
                context.read<ScreenRecordingCubit>().cancelPreparation();
              },
            ),
          ),
        ],
      ),
    );
  }
}
