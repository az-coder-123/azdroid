import 'package:flutter/material.dart';
import 'package:desk_droid/core/di/injection.dart';
import 'package:desk_droid/core/services/device_history_service.dart';
import 'package:desk_droid/core/services/network_info_service.dart';
import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/core/theme/app_typography.dart';
import 'package:desk_droid/features/discovery/domain/entities/device_entity.dart';
import 'package:desk_droid/features/discovery/presentation/widgets/empty_state/empty_state_radar_icon.dart';
import 'package:desk_droid/features/discovery/presentation/widgets/empty_state/empty_state_step_card.dart';
import 'package:desk_droid/features/discovery/presentation/widgets/empty_state/recent_devices_chips.dart';
import 'package:desk_droid/features/discovery/presentation/widgets/empty_state/usb_quick_switch_banner.dart';

/// Clean and interactive onboarding launchpad displayed when no devices are detected.
class EmptyStateView extends StatefulWidget {
  const EmptyStateView({
    super.key,
    required this.isScanning,
    required this.onScanPressed,
    this.onPairPressed,
    this.onPairWithQrPressed,
    this.onGuidePressed,
    this.onShowcasePressed,
    this.onRecentSelected,
  });

  final bool isScanning;
  final VoidCallback onScanPressed;
  final VoidCallback? onPairPressed;
  final VoidCallback? onPairWithQrPressed;
  final VoidCallback? onGuidePressed;
  final VoidCallback? onShowcasePressed;
  final ValueChanged<DeviceEntity>? onRecentSelected;

  VoidCallback? get effectivePairPressed =>
      onPairPressed ?? onPairWithQrPressed;

  @override
  State<EmptyStateView> createState() => _EmptyStateViewState();
}

class _EmptyStateViewState extends State<EmptyStateView> {
  late final Future<String?> _ipFuture;
  late final Future<List<RecentDevice>> _recentFuture;

  @override
  void initState() {
    super.initState();
    _ipFuture = sl.isRegistered<NetworkInfoService>()
        ? sl<NetworkInfoService>().getLocalIpAddress()
        : Future.value(null);
    _recentFuture = sl.isRegistered<DeviceHistoryService>()
        ? sl<DeviceHistoryService>().getRecentDevices()
        : Future.value(<RecentDevice>[]);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              EmptyStateRadarIcon(isScanning: widget.isScanning),
              const SizedBox(height: 20),
              Text(
                widget.isScanning
                    ? 'Scanning Local Network...'
                    : 'No Devices Discovered',
                style: AppTypography.display,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Follow this 3-step checklist to connect your Android phone wirelessly:',
                style: AppTypography.subtitle.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FutureBuilder<String?>(
                future: _ipFuture,
                builder: (context, snapshot) => _buildChecklist(snapshot.data),
              ),
              const SizedBox(height: 20),
              FutureBuilder<List<RecentDevice>>(
                future: _recentFuture,
                builder: (context, snapshot) {
                  return RecentDevicesChips(
                    devices: snapshot.data ?? const [],
                    onSelect: widget.onRecentSelected,
                  );
                },
              ),
              _buildActionButtons(),
              const SizedBox(height: 20),
              UsbQuickSwitchBanner(onGuidePressed: widget.onGuidePressed),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChecklist(String? macIp) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 540;
        final card1 = EmptyStateStepCard(
          stepNumber: 1,
          icon: Icons.wifi_rounded,
          title: 'Same Wi-Fi Network',
          description: 'Mac and phone must share the same LAN.',
          badgeText: macIp != null ? 'Mac: $macIp' : 'Detecting Wi-Fi...',
          badgeIcon: Icons.wifi_rounded,
          badgeColor: AppColors.statusSuccess,
        );
        final card2 = const EmptyStateStepCard(
          stepNumber: 2,
          icon: Icons.developer_mode_rounded,
          title: 'Wireless Debugging',
          description: 'Turn ON in phone Developer Options.',
          badgeText: 'Settings > Dev Options',
          badgeIcon: Icons.settings_outlined,
          badgeColor: AppColors.accent,
        );
        final card3 = const EmptyStateStepCard(
          stepNumber: 3,
          icon: Icons.phonelink_lock_rounded,
          title: 'Pair & Connect',
          description: 'Enter 6-digit Wi-Fi code or connect via IP.',
          badgeText: '6-Digit PIN / IP',
          badgeIcon: Icons.check_circle_outline_rounded,
          badgeColor: AppColors.statusWarning,
        );

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: card1),
              const SizedBox(width: 12),
              Expanded(child: card2),
              const SizedBox(width: 12),
              Expanded(child: card3),
            ],
          );
        }
        return Column(
          children: [
            card1,
            const SizedBox(height: 10),
            card2,
            const SizedBox(height: 10),
            card3,
          ],
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return Wrap(
      spacing: 12,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: widget.isScanning ? null : widget.onScanPressed,
          icon: widget.isScanning
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.refresh_rounded, size: 18),
          label: Text(
            widget.isScanning ? 'Scanning Network...' : 'Scan for Devices',
          ),
        ),
        if (widget.effectivePairPressed != null)
          OutlinedButton.icon(
            onPressed: widget.effectivePairPressed,
            icon: const Icon(Icons.phonelink_lock_rounded, size: 18),
            label: const Text('Pair with Wi-Fi Code'),
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.surface,
              side: const BorderSide(color: AppColors.accent, width: 1.2),
            ),
          ),
        if (widget.onShowcasePressed != null)
          TextButton.icon(
            onPressed: widget.onShowcasePressed,
            icon: const Icon(
              Icons.auto_awesome_rounded,
              size: 16,
              color: AppColors.accent,
            ),
            label: const Text('Explore Features'),
            style: TextButton.styleFrom(foregroundColor: AppColors.accent),
          ),
        if (widget.onGuidePressed != null)
          TextButton.icon(
            onPressed: widget.onGuidePressed,
            icon: const Icon(Icons.menu_book_rounded, size: 18),
            label: const Text('User Guide'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
          ),
      ],
    );
  }
}
