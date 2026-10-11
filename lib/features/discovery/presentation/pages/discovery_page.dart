import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wifi_desk/core/constants/app_constants.dart';
import 'package:wifi_desk/core/theme/app_colors.dart';
import 'package:wifi_desk/core/theme/app_typography.dart';
import 'package:wifi_desk/features/discovery/presentation/cubit/discovery_cubit.dart';
import 'package:wifi_desk/features/discovery/presentation/cubit/discovery_state.dart';
import 'package:wifi_desk/features/discovery/presentation/widgets/device_card.dart';
import 'package:wifi_desk/features/discovery/presentation/widgets/empty_state_view.dart';

/// Main landing page of WifiDesk hosting the device discovery dashboard.
class DiscoveryPage extends StatelessWidget {
  const DiscoveryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.wifi_tethering_rounded, color: AppColors.accent, size: 24),
            SizedBox(width: 12),
            Text(AppConstants.appName, style: AppTypography.title),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Rescan Network',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<DiscoveryCubit>().scanDevices(),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
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
                  Text('Scanning for devices on Wi-Fi...', style: AppTypography.subtitle),
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
                    const Icon(Icons.error_outline_rounded,
                        color: AppColors.statusError, size: 48),
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
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available Devices (${state.devices.length})',
                    style: AppTypography.title,
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
