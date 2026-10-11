import 'package:flutter/material.dart';
import 'package:wifi_desk/core/theme/app_colors.dart';
import 'package:wifi_desk/core/theme/app_typography.dart';
import 'package:wifi_desk/features/discovery/domain/entities/device_entity.dart';

/// Card widget rendering an individual Android device item with connect/disconnect actions.
class DeviceCard extends StatelessWidget {
  const DeviceCard({
    super.key,
    required this.device,
    required this.onConnect,
    required this.onDisconnect,
  });

  final DeviceEntity device;
  final ValueChanged<DeviceEntity> onConnect;
  final ValueChanged<String> onDisconnect;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: device.isConnected
                    ? AppColors.statusSuccess.withValues(alpha: 0.15)
                    : AppColors.accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                device.connectionType == DeviceConnectionType.usb
                    ? Icons.usb_rounded
                    : Icons.wifi_rounded,
                color: device.isConnected
                    ? AppColors.statusSuccess
                    : AppColors.accent,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name,
                    style: AppTypography.title.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${device.ipAddress}:${device.port}',
                        style: AppTypography.caption,
                      ),
                      if (device.model != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '• ${device.model}',
                          style: AppTypography.caption,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (device.isConnected)
              OutlinedButton.icon(
                onPressed: () => onDisconnect(device.id),
                icon: const Icon(Icons.link_off_rounded, size: 16),
                label: const Text('Disconnect'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.statusError,
                  side: const BorderSide(color: AppColors.statusError),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: () => onConnect(device),
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text('Connect'),
              ),
          ],
        ),
      ),
    );
  }
}
