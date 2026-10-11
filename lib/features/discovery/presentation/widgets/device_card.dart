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
    this.onPair,
    this.onMirror,
  });

  final DeviceEntity device;
  final ValueChanged<DeviceEntity> onConnect;
  final ValueChanged<String> onDisconnect;
  final ValueChanged<DeviceEntity>? onPair;
  final ValueChanged<DeviceEntity>? onMirror;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Status Icon Container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getStatusBgColor(),
                shape: BoxShape.circle,
              ),
              child: Icon(_getStatusIcon(), color: _getStatusColor(), size: 24),
            ),
            const SizedBox(width: 16),

            // Device Information Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          device.name,
                          style: AppTypography.title.copyWith(fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusBadge(),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        device.connectionType == DeviceConnectionType.usb
                            ? 'USB (${device.id})'
                            : '${device.ipAddress}:${device.port}',
                        style: AppTypography.caption,
                      ),
                      if (device.model != null)
                        Text('• ${device.model}', style: AppTypography.caption),
                      if (device.requiresPairing && device.pairingPort != null)
                        Text(
                          '• Pairing port: ${device.pairingPort}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.statusWarning,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Action Buttons
            _buildActionButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    if (device.isConnected) {
      return _Badge(label: 'Connected', color: AppColors.statusSuccess);
    } else if (device.isUnauthorized) {
      return _Badge(label: 'Unauthorized', color: AppColors.statusError);
    } else if (device.requiresPairing) {
      return _Badge(label: 'Pairing Ready', color: AppColors.statusWarning);
    } else {
      return _Badge(
        label: device.connectionType == DeviceConnectionType.usb
            ? 'USB'
            : 'Discovered',
        color: AppColors.accent,
      );
    }
  }

  Widget _buildActionButton() {
    if (device.isConnected) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton.icon(
            onPressed: () => onMirror?.call(device),
            icon: const Icon(Icons.screen_share_rounded, size: 16),
            label: const Text('Mirror'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => onDisconnect(device.id),
            icon: const Icon(Icons.link_off_rounded, size: 16),
            label: const Text('Disconnect'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.statusError,
              side: const BorderSide(color: AppColors.statusError),
            ),
          ),
        ],
      );
    }

    if (device.requiresPairing) {
      return ElevatedButton.icon(
        onPressed: () => onPair?.call(device),
        icon: const Icon(Icons.phonelink_lock_rounded, size: 16),
        label: const Text('Pair Device'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.statusWarning,
          foregroundColor: Colors.black,
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: () => onConnect(device),
      icon: const Icon(Icons.play_arrow_rounded, size: 18),
      label: const Text('Connect'),
    );
  }

  IconData _getStatusIcon() {
    if (device.isConnected) {
      return Icons.check_circle_rounded;
    }
    if (device.isUnauthorized) {
      return Icons.lock_outline_rounded;
    }
    if (device.requiresPairing) {
      return Icons.phonelink_lock_rounded;
    }
    if (device.connectionType == DeviceConnectionType.usb) {
      return Icons.usb_rounded;
    }
    return Icons.wifi_rounded;
  }

  Color _getStatusColor() {
    if (device.isConnected) {
      return AppColors.statusSuccess;
    }
    if (device.isUnauthorized) {
      return AppColors.statusError;
    }
    if (device.requiresPairing) {
      return AppColors.statusWarning;
    }
    return AppColors.accent;
  }

  Color _getStatusBgColor() {
    return _getStatusColor().withValues(alpha: 0.15);
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
