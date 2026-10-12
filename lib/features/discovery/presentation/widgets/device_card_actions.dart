import 'package:flutter/material.dart';
import 'package:wifi_desk/core/theme/app_colors.dart';
import 'package:wifi_desk/features/discovery/domain/entities/device_entity.dart';

/// Interactive button group for device actions (Connect, Mirror, Disconnect, Pair, Wi-Fi Mode).
class DeviceCardActions extends StatelessWidget {
  const DeviceCardActions({
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
    if (device.isConnected) {
      return Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed: () => onMirror?.call(device),
            icon: const Icon(Icons.screen_share_rounded, size: 16),
            label: const Text('Mirror'),
          ),
          if (device.connectionType == DeviceConnectionType.usb &&
              onSwitchToWifi != null)
            OutlinedButton.icon(
              onPressed: () => onSwitchToWifi?.call(device),
              icon: const Icon(Icons.wifi_rounded, size: 16),
              label: const Text('Wi-Fi Mode'),
            ),
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

    if (device.connectionType == DeviceConnectionType.usb &&
        onSwitchToWifi != null &&
        !device.isUnauthorized) {
      return Wrap(
        spacing: 8,
        children: [
          ElevatedButton.icon(
            onPressed: () => onConnect(device),
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: const Text('Connect'),
          ),
          OutlinedButton.icon(
            onPressed: () => onSwitchToWifi?.call(device),
            icon: const Icon(Icons.wifi_rounded, size: 16),
            label: const Text('Wi-Fi Mode'),
          ),
        ],
      );
    }

    return ElevatedButton.icon(
      onPressed: () => onConnect(device),
      icon: const Icon(Icons.play_arrow_rounded, size: 18),
      label: const Text('Connect'),
    );
  }
}
