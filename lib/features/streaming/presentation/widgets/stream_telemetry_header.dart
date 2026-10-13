import 'package:flutter/material.dart';
import 'package:wifi_desk/core/theme/app_colors.dart';
import 'package:wifi_desk/core/theme/app_typography.dart';
import 'package:wifi_desk/features/streaming/domain/entities/stream_session_entity.dart';

/// Floating telemetry header displaying real-time stream performance metrics.
class StreamTelemetryHeader extends StatelessWidget {
  const StreamTelemetryHeader({
    super.key,
    required this.session,
    required this.onClose,
    this.onToggleZenMode,
    this.isZenMode = false,
  });

  final StreamSessionEntity session;
  final VoidCallback onClose;
  final VoidCallback? onToggleZenMode;
  final bool isZenMode;

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
            _buildMetricPill(
              icon: Icons.bolt_rounded,
              label: '${session.latencyMs}ms',
              color: AppColors.statusSuccess,
            ),
            const SizedBox(width: 10),

            // Frame Rate Badge
            _buildMetricPill(
              icon: Icons.speed_rounded,
              label: '${session.fps} FPS',
              color: AppColors.accentLight,
            ),
            const SizedBox(width: 10),

            // Bitrate Badge
            _buildMetricPill(
              icon: Icons.network_check_rounded,
              label: '${session.bitrateMbps} Mbps',
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

            // Zen View Mode Toggle Action
            if (onToggleZenMode != null) ...[
              IconButton(
                icon: Icon(
                  isZenMode
                      ? Icons.fullscreen_exit_rounded
                      : Icons.fullscreen_rounded,
                  size: 20,
                  color: AppColors.textPrimary,
                ),
                tooltip: isZenMode ? 'Exit Zen Mode' : 'Zen View (Hide Bars)',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onToggleZenMode,
              ),
              const SizedBox(width: 12),
            ],

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
