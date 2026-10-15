import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:desk_droid/core/di/injection.dart';
import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/core/theme/app_typography.dart';
import 'package:desk_droid/features/logging/presentation/cubit/device_log_cubit.dart';
import 'package:desk_droid/features/logging/presentation/cubit/device_log_state.dart';
import 'package:desk_droid/features/logging/presentation/widgets/log_action_footer.dart';
import 'package:desk_droid/features/logging/presentation/widgets/log_console_table.dart';
import 'package:desk_droid/features/logging/presentation/widgets/log_detail_drawer.dart';
import 'package:desk_droid/features/logging/presentation/widgets/log_filter_bar.dart';
import 'package:desk_droid/features/logging/presentation/widgets/logcat_shortcut_handler.dart';

/// Modal dialog providing real-time Android logcat inspection, multi-tier filtering,
/// native keyboard shortcuts, and non-blocking local disk persistence.
class DeviceLogDialog extends StatefulWidget {
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
  State<DeviceLogDialog> createState() => _DeviceLogDialogState();
}

class _DeviceLogDialogState extends State<DeviceLogDialog> {
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
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

              final cubit = context.read<DeviceLogCubit>();

              return LogcatShortcutHandler(
                searchFocusNode: _searchFocusNode,
                hasSelectedEntry: state.selectedEntry != null,
                onClearConsole: cubit.clearConsole,
                onTogglePause: cubit.togglePause,
                onScrollToBottom: () {
                  if (!state.autoScroll) cubit.toggleAutoScroll();
                },
                onCloseDetail: () => cubit.selectEntry(null),
                onCloseDialog: () => Navigator.of(context).pop(),
                child: Column(
                  children: [
                    _buildHeader(context, state),
                    LogFilterBar(
                      filter: state.filter,
                      tagCounts: state.tagCounts,
                      pidCounts: state.pidCounts,
                      pidPrimaryTags: state.pidPrimaryTags,
                      searchFocusNode: _searchFocusNode,
                    ),
                    Expanded(
                      child: LogConsoleTable(
                        entries: state.filteredEntries,
                        autoScroll: state.autoScroll,
                        isPaused: state.isPaused,
                        searchQuery: state.filter.textQuery,
                        caseSensitive: state.filter.caseSensitive,
                        isRegex: state.filter.isRegex,
                        selectedEntry: state.selectedEntry,
                        bookmarkedIds: state.bookmarkedIds,
                        softWrap: state.softWrap,
                        onToggleBookmark: (id) => cubit.toggleBookmark(id),
                        onSelectEntry: (entry) => cubit.selectEntry(entry),
                        onScrollToBottom: () {
                          if (!state.autoScroll) cubit.toggleAutoScroll();
                        },
                      ),
                    ),
                    if (state.selectedEntry != null)
                      LogDetailDrawer(
                        entry: state.selectedEntry!,
                        isBookmarked: state.bookmarkedIds.contains(
                          state.selectedEntry!.id,
                        ),
                        onToggleBookmark: () =>
                            cubit.toggleBookmark(state.selectedEntry!.id),
                        onExcludeTag: () =>
                            cubit.excludeTag(state.selectedEntry!.tag),
                        onClose: () => cubit.selectEntry(null),
                      ),
                    LogActionFooter(
                      totalEntries: state.allEntries.length,
                      filteredEntries: state.filteredEntries.length,
                      recordingStatus: state.recordingStatus,
                      isPaused: state.isPaused,
                      autoScroll: state.autoScroll,
                      softWrap: state.softWrap,
                      onExportSnapshot: () => _handleExportSnapshot(context),
                    ),
                  ],
                ),
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
          const Text('Device Logcat Console', style: AppTypography.title),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Text(
              widget.deviceSerial,
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
            tooltip: 'Close Console (Esc)',
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
          const Text('Logcat Stream Failed', style: AppTypography.subtitle),
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
            onPressed: () => context.read<DeviceLogCubit>().startLogging(
              widget.deviceSerial,
            ),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry Connection'),
          ),
        ],
      ),
    );
  }

  void _handleExportSnapshot(BuildContext context) {
    final home = Platform.environment['HOME'] ?? '';
    final safe = widget.deviceSerial.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final ts = DateTime.now().millisecondsSinceEpoch;
    final path =
        '$home/Downloads/deskdroid_logs/logcat_snapshot_${safe}_$ts.log';
    context.read<DeviceLogCubit>().exportLogs(destinationPath: path);
  }
}
