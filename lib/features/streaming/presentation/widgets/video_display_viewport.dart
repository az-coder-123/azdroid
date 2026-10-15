import 'package:flutter/material.dart';
import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/core/theme/app_typography.dart';
import 'package:desk_droid/features/streaming/domain/entities/stream_session_entity.dart';

/// Renders the hardware-accelerated video display viewport preserving aspect ratio and rotation.
class VideoDisplayViewport extends StatelessWidget {
  const VideoDisplayViewport({
    super.key,
    required this.session,
    this.rotationDegrees = 0,
  });

  final StreamSessionEntity session;
  final int rotationDegrees;

  @override
  Widget build(BuildContext context) {
    final turns = (rotationDegrees ~/ 90) % 4;
    final streamWidth = session.width > 0 ? session.width.toDouble() : 1080.0;
    final streamHeight = session.height > 0
        ? session.height.toDouble()
        : 2400.0;

    return Center(
      child: FittedBox(
        fit: BoxFit.contain,
        child: RotatedBox(
          quarterTurns: turns,
          child: SizedBox(
            width: streamWidth,
            height: streamHeight,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: AppColors.border, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: session.textureId != null
                  ? Texture(textureId: session.textureId!)
                  : _buildConnectingViewport(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectingViewport(BuildContext context) {
    return Container(
      color: const Color(0xFF0D0E12),
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(
                strokeWidth: 3.0,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Initializing Video Stream',
              style: AppTypography.title.copyWith(
                fontSize: 20,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '${session.deviceName} • Hardware VideoToolbox Decoder',
              style: AppTypography.caption.copyWith(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.statusSuccess,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${session.width} × ${session.height} @ ${session.fps} FPS',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
