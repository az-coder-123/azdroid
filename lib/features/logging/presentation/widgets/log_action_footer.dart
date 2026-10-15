import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wifi_desk/core/theme/app_colors.dart';
import 'package:wifi_desk/features/logging/domain/entities/log_file_recording_status.dart';
import 'package:wifi_desk/features/logging/presentation/cubit/device_log_cubit.dart';

/// Bottom footer bar displaying buffer telemetry, recording indicator, and action buttons.
class LogActionFooter extends StatelessWidget {
  const LogActionFooter({
    super.key,
    required this.totalEntries,
    required this.filteredEntries,
    required this.recordingStatus,
    required this.isPaused,
    required this.autoScroll,
    this.softWrap = false,
    required this.onExportSnapshot,
  });

  final int totalEntries;
  final int filteredEntries;
  final LogFileRecordingStatus recordingStatus;
  final bool isPaused;
  final bool autoScroll;
  final bool softWrap;
  final VoidCallback onExportSnapshot;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DeviceLogCubit>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        children: [
          // Telemetry
          Text(
            'Showing $filteredEntries of $totalEntries lines',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 16),

          // File recording indicator
          _buildRecordingStatusBadge(),

          const Spacer(),

          // Actions
          IconButton(
            icon: Icon(
              isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              size: 18,
              color: isPaused ? AppColors.accent : AppColors.textPrimary,
            ),
            tooltip: isPaused
                ? 'Resume stream (Space)'
                : 'Pause stream (Space)',
            onPressed: cubit.togglePause,
          ),
          IconButton(
            icon: Icon(
              autoScroll
                  ? Icons.arrow_downward_rounded
                  : Icons.vertical_align_bottom_rounded,
              size: 18,
              color: autoScroll ? AppColors.accent : AppColors.textSecondary,
            ),
            tooltip: autoScroll
                ? 'Auto-scroll enabled (⌘↓)'
                : 'Auto-scroll disabled (⌘↓)',
            onPressed: cubit.toggleAutoScroll,
          ),
          IconButton(
            icon: Icon(
              Icons.wrap_text_rounded,
              size: 18,
              color: softWrap ? AppColors.accent : AppColors.textSecondary,
            ),
            tooltip: softWrap ? 'Disable soft wrap' : 'Enable soft wrap',
            onPressed: cubit.toggleSoftWrap,
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 18,
              color: AppColors.textPrimary,
            ),
            tooltip: 'Clear in-memory console (⌘K)',
            onPressed: cubit.clearConsole,
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_forever_outlined,
              size: 18,
              color: AppColors.statusError,
            ),
            tooltip: 'Clear device buffer (adb logcat -c)',
            onPressed: cubit.clearDeviceBuffer,
          ),

          const SizedBox(width: 8),
          Container(width: 1, height: 20, color: AppColors.borderSubtle),
          const SizedBox(width: 8),

          // Record to local file toggle
          _buildRecordToFileButton(context, cubit),

          const SizedBox(width: 8),

          // Export snapshot button
          OutlinedButton.icon(
            onPressed: onExportSnapshot,
            icon: const Icon(Icons.file_download_outlined, size: 14),
            label: const Text('Export', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingStatusBadge() {
    if (recordingStatus.isRecording) {
      return Tooltip(
        message: 'Streaming real-time to: ${recordingStatus.targetFilePath}',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
          decoration: BoxDecoration(
            color: AppColors.statusError.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: AppColors.statusError.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.statusError,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'REC: ${recordingStatus.formattedSize} (${recordingStatus.linesWritten} lines)',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.statusError,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.fiber_manual_record,
            size: 8,
            color: AppColors.textSecondary,
          ),
          SizedBox(width: 5),
          Text(
            'Not recording to file',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordToFileButton(BuildContext context, DeviceLogCubit cubit) {
    final isRecording = recordingStatus.isRecording;

    return ElevatedButton.icon(
      onPressed: () => cubit.toggleFileRecording(),
      icon: Icon(
        isRecording ? Icons.stop_rounded : Icons.fiber_manual_record,
        size: 14,
        color: isRecording ? Colors.white : AppColors.statusError,
      ),
      label: Text(
        isRecording ? 'Stop REC' : 'Record to File',
        style: const TextStyle(fontSize: 12),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isRecording
            ? AppColors.statusError
            : AppColors.surfaceElevated,
        foregroundColor: isRecording ? Colors.white : AppColors.textPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
