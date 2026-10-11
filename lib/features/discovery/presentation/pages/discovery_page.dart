import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wifi_desk/core/constants/app_constants.dart';
import 'package:wifi_desk/core/theme/app_colors.dart';
import 'package:wifi_desk/core/theme/app_typography.dart';
import 'package:wifi_desk/features/discovery/domain/entities/device_entity.dart';
import 'package:wifi_desk/features/discovery/presentation/cubit/discovery_cubit.dart';
import 'package:wifi_desk/features/discovery/presentation/cubit/discovery_state.dart';
import 'package:wifi_desk/features/discovery/presentation/widgets/device_card.dart';
import 'package:wifi_desk/features/discovery/presentation/widgets/empty_state_view.dart';
import 'package:wifi_desk/features/discovery/presentation/widgets/manual_connect_dialog.dart';
import 'package:wifi_desk/features/discovery/presentation/widgets/pairing_dialog.dart';

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
      onPairingSuccess: () => context.read<DiscoveryCubit>().scanDevices(),
    );
  }

  void _openManualConnectDialog() {
    ManualConnectDialog.show(
      context,
      onConnect: (ip, port) => context.read<DiscoveryCubit>().manualConnect(
        ipAddress: ip,
        port: port,
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
              children: [
                const Icon(
                  Icons.wifi_tethering_rounded,
                  color: AppColors.accent,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(AppConstants.appName, style: AppTypography.title),
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
          TextButton.icon(
            icon: const Icon(Icons.phonelink_setup_rounded, size: 16),
            label: const Text('Pair Device'),
            style: TextButton.styleFrom(foregroundColor: AppColors.accent),
            onPressed: () => _openPairingDialog(),
          ),
          const SizedBox(width: 4),
          TextButton.icon(
            icon: const Icon(Icons.add_link_rounded, size: 16),
            label: const Text('Direct IP'),
            style: TextButton.styleFrom(foregroundColor: AppColors.textPrimary),
            onPressed: _openManualConnectDialog,
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Rescan Network',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<DiscoveryCubit>().scanDevices(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<DiscoveryCubit, DiscoveryState>(
        builder: (context, state) {
          if (state is DiscoveryLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Scanning for Android devices & mDNS services...',
                    style: AppTypography.subtitle,
                  ),
                ],
              ),
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
                      Text(
                        'Discovered Devices (${state.devices.length})',
                        style: AppTypography.title,
                      ),
                      if (state.isAutoScanning)
                        Text(
                          'Updating in background...',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.accentLight,
                          ),
                        ),
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
                          onConnect: (d) =>
                              context.read<DiscoveryCubit>().connect(d),
                          onDisconnect: (id) =>
                              context.read<DiscoveryCubit>().disconnect(id),
                          onPair: (d) => _openPairingDialog(d),
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
          );
        },
      ),
    );
  }
}
