import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/features/productivity/presentation/cubit/screen_recording_cubit.dart';
import 'package:desk_droid/features/productivity/presentation/cubit/screen_recording_state.dart';

/// Full-surface interactive countdown animation overlay rendered over phone screen
/// before screen recording commences.
class RecordingCountdownOverlay extends StatelessWidget {
  const RecordingCountdownOverlay({super.key, required this.deviceSerial});

  final String deviceSerial;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScreenRecordingCubit, ScreenRecordingState>(
      builder: (context, state) {
        if (state is! ScreenRecordingCountdown ||
            state.deviceSerial != deviceSerial) {
          return const SizedBox.shrink();
        }

        final remaining = state.remainingSeconds;

        return Material(
          type: MaterialType.transparency,
          child: Container(
            color: Colors.black.withValues(alpha: 0.45),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Circular Pulse Countdown Badge
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: CurvedAnimation(
                          parent: animation,
                          curve: Curves.elasticOut,
                        ),
                        child: child,
                      );
                    },
                    child: Container(
                      key: ValueKey<int>(remaining),
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surface.withValues(alpha: 0.92),
                        border: Border.all(
                          color: AppColors.statusError,
                          width: 3.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.statusError.withValues(alpha: 0.5),
                            blurRadius: 28,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$remaining',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          fontFamily: 'SF Pro Display',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Subtitle Prompt
                  const Text(
                    'Preparing screen recording...',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontFamily: 'SF Pro Text',
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Action Buttons: Start Now & Cancel
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Skip Countdown & Start Now
                      TextButton.icon(
                        onPressed: () {
                          context.read<ScreenRecordingCubit>().startRecording(
                            deviceSerial,
                          );
                        },
                        icon: const Icon(Icons.flash_on_rounded, size: 14),
                        label: const Text('Start Now'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Cancel
                      TextButton.icon(
                        onPressed: () {
                          context
                              .read<ScreenRecordingCubit>()
                              .cancelPreparation();
                        },
                        icon: const Icon(Icons.close_rounded, size: 14),
                        label: const Text('Cancel (Esc)'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          backgroundColor: Colors.black38,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
