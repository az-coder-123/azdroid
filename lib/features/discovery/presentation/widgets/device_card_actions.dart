import 'package:desk_droid/core/models/device_entity.dart';
import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/features/logging/presentation/widgets/device_log_dialog.dart';
import 'package:flutter/material.dart';

/// Interactive button group for device actions (Connect, Mirror, Disconnect, Pair, Wi-Fi Mode).
class DeviceCardActions extends StatefulWidget {
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
  State<DeviceCardActions> createState() => _DeviceCardActionsState();
}

class _DeviceCardActionsState extends State<DeviceCardActions> {
  DeviceConnectionType _selectedTransport = DeviceConnectionType.wireless;

  @override
  Widget build(BuildContext context) {
    final device = widget.device;

    if (device.isDualConnected) {
      return Wrap(
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SegmentedButton<DeviceConnectionType>(
            segments: const [
              ButtonSegment(
                value: DeviceConnectionType.wireless,
                icon: Icon(Icons.wifi_rounded, size: 14),
                label: Text('Wi-Fi', style: TextStyle(fontSize: 12)),
              ),
              ButtonSegment(
                value: DeviceConnectionType.usb,
                icon: Icon(Icons.usb_rounded, size: 14),
                label: Text('USB', style: TextStyle(fontSize: 12)),
              ),
            ],
            selected: {_selectedTransport},
            onSelectionChanged: (selection) {
              setState(() {
                _selectedTransport = selection.first;
              });
            },
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final target = _selectedTransport == DeviceConnectionType.usb
                  ? device.toUsbEndpoint()
                  : device.toWirelessEndpoint();
              widget.onMirror?.call(target);
            },
            icon: const Icon(Icons.screen_share_rounded, size: 16),
            label: const Text('Mirror'),
          ),
          OutlinedButton.icon(
            onPressed: () =>
                widget.onDisconnect(device.wirelessSerial ?? device.id),
            icon: const Icon(Icons.link_off_rounded, size: 16),
            label: const Text('Disconnect'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.statusError,
              side: const BorderSide(color: AppColors.statusError),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.terminal_rounded,
              size: 16,
              color: AppColors.textSecondary,
            ),
            tooltip: 'View Device Logs',
            visualDensity: VisualDensity.compact,
            onPressed: () => DeviceLogDialog.show(
              context,
              device.wirelessSerial ?? device.id,
            ),
          ),
        ],
      );
    }

    if (device.isConnected) {
      return Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed: () => widget.onMirror?.call(device),
            icon: const Icon(Icons.screen_share_rounded, size: 16),
            label: const Text('Mirror'),
          ),
          if (device.connectionType == DeviceConnectionType.usb &&
              widget.onSwitchToWifi != null)
            OutlinedButton.icon(
              onPressed: () => widget.onSwitchToWifi?.call(device),
              icon: const Icon(Icons.wifi_rounded, size: 16),
              label: const Text('Wi-Fi Mode'),
            ),
          OutlinedButton.icon(
            onPressed: () => widget.onDisconnect(device.id),
            icon: const Icon(Icons.link_off_rounded, size: 16),
            label: const Text('Disconnect'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.statusError,
              side: const BorderSide(color: AppColors.statusError),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.terminal_rounded,
              size: 16,
              color: AppColors.textSecondary,
            ),
            tooltip: 'View Device Logs',
            visualDensity: VisualDensity.compact,
            onPressed: () => DeviceLogDialog.show(context, device.id),
          ),
        ],
      );
    }

    if (device.requiresPairing) {
      return ElevatedButton.icon(
        onPressed: () => widget.onPair?.call(device),
        icon: const Icon(Icons.phonelink_lock_rounded, size: 16),
        label: const Text('Pair Device'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.statusWarning,
          foregroundColor: Colors.black,
        ),
      );
    }

    if (device.connectionType == DeviceConnectionType.usb &&
        widget.onSwitchToWifi != null &&
        !device.isUnauthorized) {
      return Wrap(
        spacing: 8,
        children: [
          ElevatedButton.icon(
            onPressed: () => widget.onConnect(device),
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: const Text('Connect'),
          ),
          OutlinedButton.icon(
            onPressed: () => widget.onSwitchToWifi?.call(device),
            icon: const Icon(Icons.wifi_rounded, size: 16),
            label: const Text('Wi-Fi Mode'),
          ),
        ],
      );
    }

    return ElevatedButton.icon(
      onPressed: () => widget.onConnect(device),
      icon: const Icon(Icons.play_arrow_rounded, size: 18),
      label: const Text('Connect'),
    );
  }
}
