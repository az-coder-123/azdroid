import 'package:flutter/material.dart';
import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/features/menubar/domain/entities/menu_bar_status_entity.dart';

/// Active device session card rendering device name, battery, and live latency/FPS telemetry.
class MenuBarSessionCard extends StatelessWidget {
  const MenuBarSessionCard({super.key, required this.status});

  final MenuBarStatusEntity status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.phone_android_rounded,
                size: 16,
                color: AppColors.textPrimary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  status.activeDeviceName ?? 'Connected Device',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (status.batteryLevel != null) ...[
                const Icon(
                  Icons.battery_charging_full_rounded,
                  size: 14,
                  color: AppColors.statusSuccess,
                ),
                const SizedBox(width: 3),
                Text(
                  '${status.batteryLevel}%',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildTelemetryChip(
                icon: Icons.speed_rounded,
                label: '${status.latencyMs ?? 18}ms',
                color: AppColors.accentLight,
              ),
              const SizedBox(width: 8),
              _buildTelemetryChip(
                icon: Icons.motion_photos_on_rounded,
                label: '${status.fps ?? 60} FPS',
                color: AppColors.statusSuccess,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
