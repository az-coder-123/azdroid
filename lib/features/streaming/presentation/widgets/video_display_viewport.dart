import 'package:flutter/material.dart';
import 'package:wifi_desk/core/theme/app_colors.dart';
import 'package:wifi_desk/core/theme/app_typography.dart';
import 'package:wifi_desk/features/streaming/domain/entities/stream_session_entity.dart';

/// Renders the low-latency display viewport preserving aspect ratio and rotation.
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
                  : _buildSimulatedViewport(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSimulatedViewport(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1C23), Color(0xFF111217), Color(0xFF0A0B0E)],
        ),
      ),
      child: Column(
        children: [
          // Android Status Bar Simulation
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  TimeOfDay.now().format(context),
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Row(
                  children: [
                    Icon(Icons.wifi_rounded, size: 14, color: AppColors.accent),
                    SizedBox(width: 6),
                    Icon(
                      Icons.battery_full_rounded,
                      size: 14,
                      color: AppColors.statusSuccess,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),

          // Active Stream Canvas
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 20.0,
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.screen_share_rounded,
                  size: 40,
                  color: AppColors.accent,
                ),
                const SizedBox(height: 10),
                Text(
                  session.deviceName,
                  style: AppTypography.title.copyWith(fontSize: 15),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${session.width} × ${session.height} @ ${session.fps} FPS',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.statusSuccess,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      'Live Stream (${session.latencyMs}ms)',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.statusSuccess,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),

          // Android Navigation Pill Bar
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            width: 72,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
