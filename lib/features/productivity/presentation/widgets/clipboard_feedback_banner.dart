import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/features/productivity/domain/entities/clipboard_item_entity.dart';
import 'package:desk_droid/features/productivity/presentation/cubit/clipboard_cubit.dart';
import 'package:desk_droid/features/productivity/presentation/cubit/clipboard_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Floating toast HUD banner providing instant non-intrusive feedback
/// when clipboard content is synchronized between macOS and Android.
class ClipboardFeedbackBanner extends StatelessWidget {
  const ClipboardFeedbackBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClipboardCubit, ClipboardState>(
      builder: (context, state) {
        if (state is ClipboardSyncing) {
          return _buildSyncingPill(state.direction);
        }

        if (state is ClipboardSynced) {
          return _buildSyncedPill(context, state.lastItem);
        }

        if (state is ClipboardError) {
          return _buildErrorPill(context, state.errorMessage);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSyncingPill(String direction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.94),
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Syncing clipboard ($direction)...',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncedPill(BuildContext context, ClipboardItemEntity item) {
    final isHost = item.source == ClipboardSource.host;
    final directionText = isHost ? 'Mac ➔ Android' : 'Android ➔ Mac';
    final previewText = item.text.trim().replaceAll('\n', ' ');
    final truncated = previewText.length > 32
        ? '${previewText.substring(0, 32)}…'
        : previewText;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.statusSuccess.withValues(alpha: 0.6),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 16,
            color: AppColors.statusSuccess,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Clipboard synced ($directionText): "$truncated"',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => context.read<ClipboardCubit>().reset(),
            child: const Icon(
              Icons.close_rounded,
              size: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorPill(BuildContext context, String error) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.statusError.withValues(alpha: 0.6),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 16,
            color: AppColors.statusError,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              error,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => context.read<ClipboardCubit>().reset(),
            child: const Icon(
              Icons.close_rounded,
              size: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
