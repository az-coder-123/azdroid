import 'package:flutter/material.dart';
import 'package:desk_droid/core/services/device_history_service.dart';
import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/core/theme/app_typography.dart';
import 'package:desk_droid/features/discovery/domain/entities/device_entity.dart';

/// Horizontal wrap of recent device chips for 1-click reconnecting.
class RecentDevicesChips extends StatelessWidget {
  const RecentDevicesChips({super.key, required this.devices, this.onSelect});

  final List<RecentDevice> devices;
  final ValueChanged<DeviceEntity>? onSelect;

  @override
  Widget build(BuildContext context) {
    if (devices.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        children: [
          Text(
            'Recent Devices:',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: devices.map((d) {
              return ActionChip(
                avatar: const Icon(
                  Icons.wifi_rounded,
                  size: 14,
                  color: AppColors.accent,
                ),
                label: Text(
                  '${d.name} (${d.ipAddress})',
                  style: const TextStyle(fontSize: 11),
                ),
                backgroundColor: AppColors.surface,
                side: const BorderSide(color: AppColors.borderSubtle),
                onPressed: () => onSelect?.call(
                  DeviceEntity(
                    id: d.id,
                    name: d.name,
                    ipAddress: d.ipAddress,
                    port: d.port,
                    connectionType: DeviceConnectionType.wireless,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
