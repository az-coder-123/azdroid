import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wifi_desk/core/theme/app_colors.dart';
import 'package:wifi_desk/features/productivity/presentation/cubit/screenshot_cubit.dart';
import 'package:wifi_desk/features/productivity/presentation/cubit/screenshot_state.dart';
import 'package:wifi_desk/features/productivity/presentation/widgets/screenshot_success_card.dart';

/// Floating notification HUD banner providing instant feedback and actions
/// for captured screenshots (Show in Finder, Open, Copied to clipboard).
class ScreenshotFeedbackBanner extends StatelessWidget {
  const ScreenshotFeedbackBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ScreenshotCubit, ScreenshotState>(
      listener: (context, state) {
        if (state is ScreenshotSuccess) {
          Future<void>.delayed(const Duration(seconds: 6), () {
            if (context.mounted &&
                context.read<ScreenshotCubit>().state == state) {
              context.read<ScreenshotCubit>().reset();
            }
          });
        }
      },
      builder: (context, state) {
        if (state is ScreenshotCapturing) {
          return _buildCapturingPill();
        }

        if (state is ScreenshotSuccess) {
          return ScreenshotSuccessCard(screenshot: state.screenshot);
        }

        if (state is ScreenshotFailure) {
          return _buildFailureCard(context, state);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildCapturingPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
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
            'Capturing device display...',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
              fontFamily: 'SF Pro Text',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailureCard(BuildContext context, ScreenshotFailure state) {
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
              'Screenshot failed: ${state.errorMessage}',
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
            onPressed: () => context.read<ScreenshotCubit>().reset(),
          ),
        ],
      ),
    );
  }
}
