import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wifi_desk/core/constants/app_constants.dart';
import 'package:wifi_desk/core/theme/app_colors.dart';
import 'package:wifi_desk/core/theme/app_typography.dart';
import 'package:wifi_desk/features/discovery/domain/entities/device_entity.dart';
import 'package:wifi_desk/features/discovery/presentation/cubit/discovery_cubit.dart';
import 'package:wifi_desk/features/discovery/presentation/cubit/discovery_state.dart';
import 'package:wifi_desk/features/discovery/presentation/widgets/device_card.dart';
import 'package:wifi_desk/features/discovery/presentation/widgets/discovery_app_bar_actions.dart';
import 'package:wifi_desk/features/discovery/presentation/widgets/empty_state_view.dart';
import 'package:wifi_desk/features/discovery/presentation/widgets/manual_connect_dialog.dart';
import 'package:wifi_desk/features/discovery/presentation/widgets/pairing_dialog.dart';
import 'package:wifi_desk/features/guide/presentation/widgets/user_guide_dialog.dart';
import 'package:wifi_desk/features/streaming/presentation/pages/mirroring_page.dart';

/// Main landing page of WifiDesk hosting the device discovery and pairing dashboard.
class DiscoveryPage extends StatefulWidget {
  const DiscoveryPage({super.key});

  @override
  State<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends State<DiscoveryPage> {
  late final DiscoveryCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<DiscoveryCubit>();
    _cubit.scanDevices();
    _cubit.startAutoScan();
  }

  @override
  void dispose() {
    _cubit.stopAutoScan();
    super.dispose();
  }

  void _openPairingDialog([DeviceEntity? device]) {
    PairingDialog.show(
      context,
      initialDevice: device,
      onPairingSuccess: _cubit.scanDevices,
    );
  }

  void _openManualConnectDialog() {
    ManualConnectDialog.show(
      context,
      onConnect: (ip, port) => _cubit.manualConnect(ipAddress: ip, port: port),
    );
  }

  void _startMirroring(DeviceEntity device) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => MirroringPage(device: device)),
    );
  }

  Future<void> _switchUsbToWifi(DeviceEntity device) async {
    final scaffold = ScaffoldMessenger.of(context);
    final ok = await context.read<DiscoveryCubit>().switchUsbToWifi(device);
    if (!mounted) return;
    scaffold.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Switched ${device.name} to Wi-Fi mode!'
              : 'Failed to switch ${device.name} to Wi-Fi mode.',
        ),
        backgroundColor: ok ? AppColors.statusSuccess : AppColors.statusError,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<DiscoveryCubit, DiscoveryState>(
          builder: (context, state) {
            final isScanning =
                state is DiscoveryLoading ||
                (state is DiscoveryLoaded && state.isAutoScanning);

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.wifi_tethering_rounded,
                  color: AppColors.accent,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Flexible(
                  child: Text(
                    AppConstants.appName,
                    style: AppTypography.title,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isScanning) ...[
                  const SizedBox(width: 10),
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.accentLight,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        actions: [
          DiscoveryAppBarActions(
            onPairDevice: _openPairingDialog,
            onDirectIp: _openManualConnectDialog,
            onUserGuide: () => UserGuideDialog.show(context),
            onRescan: () => context.read<DiscoveryCubit>().scanDevices(),
          ),
        ],
      ),
      body: BlocBuilder<DiscoveryCubit, DiscoveryState>(
        buildWhen: (previous, current) {
          if (previous.runtimeType != current.runtimeType) return true;
          if (previous is DiscoveryLoaded && current is DiscoveryLoaded) {
            return previous.devices != current.devices;
          }
          return true;
        },
        builder: (context, state) {
          if (state is DiscoveryLoading) {
            return EmptyStateView(
              isScanning: true,
              onScanPressed: () => context.read<DiscoveryCubit>().scanDevices(),
              onPairPressed: () => _openPairingDialog(),
              onGuidePressed: () => UserGuideDialog.show(context),
            );
          }

          if (state is DiscoveryError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.statusError,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(state.message, style: AppTypography.body),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () =>
                          context.read<DiscoveryCubit>().scanDevices(),
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is DiscoveryLoaded && state.devices.isNotEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Discovered Devices (${state.devices.length})',
                          style: AppTypography.title,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (state.isAutoScanning) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Updating...',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.accentLight,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: state.devices.length,
                      itemBuilder: (context, index) {
                        final device = state.devices[index];
                        return DeviceCard(
                          device: device,
                          onConnect: (d) async {
                            await context.read<DiscoveryCubit>().connect(d);
                            if (context.mounted) _startMirroring(d);
                          },
                          onDisconnect: (id) =>
                              context.read<DiscoveryCubit>().disconnect(id),
                          onPair: (d) => _openPairingDialog(d),
                          onMirror: (d) => _startMirroring(d),
                          onSwitchToWifi: (d) => _switchUsbToWifi(d),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }

          // Initial or empty list
          return EmptyStateView(
            isScanning: false,
            onScanPressed: () => context.read<DiscoveryCubit>().scanDevices(),
            onPairPressed: () => _openPairingDialog(),
            onGuidePressed: () => UserGuideDialog.show(context),
            onRecentSelected: (d) async {
              await context.read<DiscoveryCubit>().connect(d);
              if (context.mounted) _startMirroring(d);
            },
          );
        },
      ),
    );
  }
}
