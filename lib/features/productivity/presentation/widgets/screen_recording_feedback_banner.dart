import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wifi_desk/core/theme/app_colors.dart';
import 'package:wifi_desk/features/productivity/presentation/cubit/screen_recording_cubit.dart';
import 'package:wifi_desk/features/productivity/presentation/cubit/screen_recording_state.dart';
import 'package:wifi_desk/features/productivity/presentation/widgets/recording_setup_pill.dart';
import 'package:wifi_desk/features/productivity/presentation/widgets/screen_recording_success_card.dart';

/// Floating notification HUD banner providing live recording indicator and saved actions.
class ScreenRecordingFeedbackBanner extends StatelessWidget {
  const ScreenRecordingFeedbackBanner({super.key});

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ScreenRecordingCubit, ScreenRecordingState>(
      listener: (context, state) {
        if (state is ScreenRecordingSuccess) {
          Future<void>.delayed(const Duration(seconds: 6), () {
            if (context.mounted &&
                context.read<ScreenRecordingCubit>().state == state) {
              context.read<ScreenRecordingCubit>().reset();
            }
          });
        }
      },
      builder: (context, state) {
        if (state is ScreenRecordingPreparing) {
          return RecordingSetupPill(state: state);
        }

        if (state is ScreenRecordingActive) {
          return _buildRecordingPill(context, state);
        }

        if (state is ScreenRecordingFinalizing) {
          return _buildFinalizingPill();
        }

        if (state is ScreenRecordingSuccess) {
          return ScreenRecordingSuccessCard(recording: state.recording);
        }

        if (state is ScreenRecordingFailure) {
          return _buildFailureCard(context, state);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildRecordingPill(
    BuildContext context,
    ScreenRecordingActive state,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.statusError.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.statusError,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'REC ${_formatDuration(state.duration)}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'SF Pro Text',
            ),
          ),
          const SizedBox(width: 10),
          // Stop & Save
          InkWell(
            onTap: () => context.read<ScreenRecordingCubit>().stopRecording(),
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.statusError.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'STOP',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.statusError,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Discard / Cancel
          Tooltip(
            message: 'Discard recording (do not save)',
            child: InkWell(
              onTap: () =>
                  context.read<ScreenRecordingCubit>().cancelRecording(),
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Text(
                  'DISCARD',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalizingPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.accent,
            ),
          ),
          SizedBox(width: 8),
          Text(
            'Saving MP4 video...',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textPrimary,
              fontFamily: 'SF Pro Text',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailureCard(BuildContext context, ScreenRecordingFailure state) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.statusError.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 20,
            color: AppColors.statusError,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Recording failed: ${state.errorMessage}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.statusError,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            color: AppColors.textTertiary,
            onPressed: () => context.read<ScreenRecordingCubit>().reset(),
          ),
        ],
      ),
    );
  }
}
