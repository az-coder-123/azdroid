import 'package:desk_droid/core/models/device_entity.dart';
import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/core/theme/app_typography.dart';
import 'package:desk_droid/features/discovery/presentation/widgets/device_card_actions.dart';
import 'package:desk_droid/features/discovery/presentation/widgets/device_status_badge.dart';
import 'package:flutter/material.dart';

/// Card widget rendering an individual Android device item with connect/disconnect actions.
class DeviceCard extends StatelessWidget {
  const DeviceCard({
    super.key,
    required this.device,
    required this.onConnect,
    required this.onDisconnect,
    this.onPair,
    this.onMirror,
    this.onSwitchToWifi,
  });

  final DeviceEntity device;
  final ValueChanged<DeviceEntity> onConnect;
  final ValueChanged<String> onDisconnect;
  final ValueChanged<DeviceEntity>? onPair;
  final ValueChanged<DeviceEntity>? onMirror;
  final ValueChanged<DeviceEntity>? onSwitchToWifi;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 620;
            final actions = DeviceCardActions(
              device: device,
              onConnect: onConnect,
              onDisconnect: onDisconnect,
              onPair: onPair,
              onMirror: onMirror,
              onSwitchToWifi: onSwitchToWifi,
            );

            if (isCompact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: _getStatusBgColor(),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getStatusIcon(),
                          color: _getStatusColor(),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _buildDeviceDetails()),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(alignment: Alignment.centerRight, child: actions),
                ],
              );
            }

            return Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getStatusBgColor(),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getStatusIcon(),
                    color: _getStatusColor(),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: _buildDeviceDetails()),
                const SizedBox(width: 12),
                actions,
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDeviceDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              device.name,
              style: AppTypography.title.copyWith(fontSize: 16),
            ),
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
              device.isDualConnected
                  ? 'USB (${device.usbSerial}) • Wi-Fi (${device.wirelessSerial ?? "${device.ipAddress}:${device.port}"})'
                  : device.connectionType == DeviceConnectionType.usb
                  ? 'USB (${device.id})'
                  : '${device.ipAddress}:${device.port}',
              style: AppTypography.caption,
            ),
            if (device.model != null &&
                device.model != device.name &&
                !device.isDualConnected)
              Text('• ${device.model}', style: AppTypography.caption),
            if (device.requiresPairing && device.pairingPort != null)
              Text(
                '• Pairing port: ${device.pairingPort}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.statusWarning,
                ),
              ),
            if (device.isXiaomi) _buildXiaomiBadge(),
          ],
        ),
      ],
    );
  }

  Widget _buildXiaomiBadge() {
    return Tooltip(
      message: 'Xiaomi/HyperOS: Enable "USB debugging (Security settings)" for input control.',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.statusWarning.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: AppColors.statusWarning.withValues(alpha: 0.4),
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 11,
              color: AppColors.statusWarning,
            ),
            SizedBox(width: 3),
            Text(
              'MIUI/HyperOS Tip',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.statusWarning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    if (device.isDualConnected) {
      return const Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          DeviceStatusBadge(label: 'Connected', color: AppColors.statusSuccess),
          DeviceStatusBadge(label: 'Dual Mode', color: AppColors.accent),
        ],
      );
    } else if (device.isConnected) {
      return const DeviceStatusBadge(
        label: 'Connected',
        color: AppColors.statusSuccess,
      );
    } else if (device.isUnauthorized) {
      return const DeviceStatusBadge(
        label: 'Unauthorized',
        color: AppColors.statusError,
      );
    } else if (device.requiresPairing) {
      return const DeviceStatusBadge(
        label: 'Pairing Ready',
        color: AppColors.statusWarning,
      );
    } else {
      return DeviceStatusBadge(
        label: device.connectionType == DeviceConnectionType.usb
            ? 'USB'
            : 'Discovered',
        color: AppColors.accent,
      );
    }
  }

  IconData _getStatusIcon() {
    if (device.isDualConnected || device.isConnected) {
      return Icons.check_circle_rounded;
    }
    if (device.isUnauthorized) return Icons.lock_outline_rounded;
    if (device.requiresPairing) return Icons.phonelink_lock_rounded;
    if (device.connectionType == DeviceConnectionType.usb) {
      return Icons.usb_rounded;
    }
    return Icons.wifi_rounded;
  }

  Color _getStatusColor() {
    if (device.isConnected) return AppColors.statusSuccess;
    if (device.isUnauthorized) return AppColors.statusError;
    if (device.requiresPairing) return AppColors.statusWarning;
    return AppColors.accent;
  }

  Color _getStatusBgColor() => _getStatusColor().withValues(alpha: 0.15);
}
