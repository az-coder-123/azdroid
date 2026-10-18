import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/core/theme/app_typography.dart';
import 'package:desk_droid/features/streaming/domain/entities/stream_session_entity.dart';
import 'package:desk_droid/features/streaming/domain/entities/stream_telemetry.dart';
import 'package:desk_droid/features/streaming/presentation/widgets/stream_telemetry_labels.dart';
import 'package:flutter/material.dart';

/// Floating telemetry header displaying real-time stream performance metrics.
class StreamTelemetryHeader extends StatelessWidget {
  const StreamTelemetryHeader({
    super.key,
    required this.session,
    this.telemetry,
    required this.onClose,
  });

  final StreamSessionEntity session;

  /// Measured values; `null` until the first sample arrives.
  final StreamTelemetry? telemetry;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Device Name & Status
            Row(
              children: [
                Tooltip(
                  message: _isLive ? 'Streaming' : 'Waiting for video',
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _isLive
                          ? AppColors.statusSuccess
                          : AppColors.statusWarning,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  session.deviceName,
                  style: AppTypography.subtitle.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            _buildDivider(),
            const SizedBox(width: 16),

            // Latency Badge
            Tooltip(
              message: StreamTelemetryLabels.latencyTooltip,
              child: _buildMetricPill(
                icon: Icons.bolt_rounded,
                label: StreamTelemetryLabels.latency(telemetry),
                color: AppColors.statusSuccess,
              ),
            ),
            const SizedBox(width: 10),

            // Frame Rate Badge
            _buildMetricPill(
              icon: Icons.speed_rounded,
              label: StreamTelemetryLabels.fps(telemetry),
              color: AppColors.accentLight,
            ),
            const SizedBox(width: 10),

            // Bitrate Badge
            _buildMetricPill(
              icon: Icons.network_check_rounded,
              label: StreamTelemetryLabels.bitrate(telemetry),
              color: AppColors.accent,
            ),
            const SizedBox(width: 10),

            // Screen Off Indicator
            if (session.isScreenOff) ...[
              _buildMetricPill(
                icon: Icons.screen_lock_portrait_rounded,
                label: 'Screen Off',
                color: AppColors.statusWarning,
              ),
              const SizedBox(width: 10),
            ],

            _buildDivider(),
            const SizedBox(width: 12),

            // Close / Disconnect Action
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18),
              tooltip: 'End Mirroring Session',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onClose,
            ),
          ],
        ),
      ),
    );
  }

  bool get _isLive => telemetry?.health == StreamHealth.live;

  Widget _buildDivider() {
    return Container(width: 1, height: 16, color: AppColors.border);
  }

  Widget _buildMetricPill({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
