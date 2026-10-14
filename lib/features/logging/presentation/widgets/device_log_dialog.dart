import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wifi_desk/core/di/injection.dart';
import 'package:wifi_desk/core/theme/app_colors.dart';
import 'package:wifi_desk/core/theme/app_typography.dart';
import 'package:wifi_desk/features/logging/presentation/cubit/device_log_cubit.dart';
import 'package:wifi_desk/features/logging/presentation/cubit/device_log_state.dart';
import 'package:wifi_desk/features/logging/presentation/widgets/log_action_footer.dart';
import 'package:wifi_desk/features/logging/presentation/widgets/log_console_table.dart';
import 'package:wifi_desk/features/logging/presentation/widgets/log_filter_bar.dart';

/// Modal dialog providing real-time Android logcat inspection, multi-tier filtering,
/// and non-blocking local disk persistence.
class DeviceLogDialog extends StatelessWidget {
  const DeviceLogDialog({super.key, required this.deviceSerial});

  final String deviceSerial;

  /// Displays the [DeviceLogDialog].
  static Future<void> show(BuildContext context, String deviceSerial) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => BlocProvider<DeviceLogCubit>(
        create: (_) => sl<DeviceLogCubit>()..startLogging(deviceSerial),
        child: DeviceLogDialog(deviceSerial: deviceSerial),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: const BorderSide(color: AppColors.border),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 1120,
          maxHeight: 740,
          minWidth: 600,
          minHeight: 400,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.0),
          child: BlocConsumer<DeviceLogCubit, DeviceLogState>(
            listener: (context, state) {
              if (state is DeviceLogStreaming &&
                  state.feedbackMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.feedbackMessage!),
                    duration: const Duration(seconds: 3),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state is DeviceLogError) {
                return _buildErrorState(context, state);
              }

              if (state is! DeviceLogStreaming) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                );
              }

              return Column(
                children: [
                  _buildHeader(context, state),
                  LogFilterBar(filter: state.filter),
                  Expanded(
                    child: LogConsoleTable(
                      entries: state.filteredEntries,
                      autoScroll: state.autoScroll,
                      isPaused: state.isPaused,
                      searchQuery: state.filter.textQuery,
                      onScrollToBottom: () {
                        if (!state.autoScroll) {
                          context.read<DeviceLogCubit>().toggleAutoScroll();
                        }
                      },
                    ),
                  ),
                  LogActionFooter(
                    totalEntries: state.allEntries.length,
                    filteredEntries: state.filteredEntries.length,
                    recordingStatus: state.recordingStatus,
                    isPaused: state.isPaused,
                    autoScroll: state.autoScroll,
                    onExportSnapshot: () => _handleExportSnapshot(context),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, DeviceLogStreaming state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        children: [
          const Icon(Icons.terminal_rounded, size: 20, color: AppColors.accent),
          const SizedBox(width: 10),
          Text('Device Logcat Console', style: AppTypography.title),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Text(
              deviceSerial,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(
              Icons.close_rounded,
              size: 20,
              color: AppColors.textSecondary,
            ),
            tooltip: 'Close Console',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, DeviceLogError state) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: AppColors.statusError,
          ),
          const SizedBox(height: 16),
          Text('Logcat Stream Failed', style: AppTypography.subtitle),
          const SizedBox(height: 8),
          Text(
            state.message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () =>
                context.read<DeviceLogCubit>().startLogging(deviceSerial),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry Connection'),
          ),
        ],
      ),
    );
  }

  void _handleExportSnapshot(BuildContext context) {
    final home = Platform.environment['HOME'] ?? '';
    final sanitizedSerial = deviceSerial.replaceAll(
      RegExp(r'[^a-zA-Z0-9_-]'),
      '_',
    );
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path =
        '$home/Downloads/wifidesk_logs/logcat_snapshot_${sanitizedSerial}_$timestamp.log';

    context.read<DeviceLogCubit>().exportLogs(destinationPath: path);
  }
}
