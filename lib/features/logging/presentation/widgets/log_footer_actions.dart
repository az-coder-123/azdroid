import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wifi_desk/core/theme/app_colors.dart';
import 'package:wifi_desk/features/logging/domain/entities/log_file_recording_status.dart';
import 'package:wifi_desk/features/logging/presentation/cubit/device_log_cubit.dart';

/// Action controls cluster rendered on the right side of the Logcat footer.
class LogFooterActions extends StatelessWidget {
  const LogFooterActions({
    super.key,
    required this.isPaused,
    required this.autoScroll,
    required this.softWrap,
    required this.recordingStatus,
    required this.isCompact,
    required this.onExportSnapshot,
  });

  final bool isPaused;
  final bool autoScroll;
  final bool softWrap;
  final LogFileRecordingStatus recordingStatus;
  final bool isCompact;
  final VoidCallback onExportSnapshot;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DeviceLogCubit>();
    final isRecording = recordingStatus.isRecording;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          padding: const EdgeInsets.all(6),
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          icon: Icon(
            isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            size: 18,
            color: isPaused ? AppColors.accent : AppColors.textPrimary,
          ),
          tooltip: isPaused ? 'Resume stream (Space)' : 'Pause stream (Space)',
          onPressed: cubit.togglePause,
        ),
        IconButton(
          padding: const EdgeInsets.all(6),
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
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
          padding: const EdgeInsets.all(6),
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          icon: Icon(
            Icons.wrap_text_rounded,
            size: 18,
            color: softWrap ? AppColors.accent : AppColors.textSecondary,
          ),
          tooltip: softWrap ? 'Disable soft wrap' : 'Enable soft wrap',
          onPressed: cubit.toggleSoftWrap,
        ),
        IconButton(
          padding: const EdgeInsets.all(6),
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          icon: const Icon(
            Icons.delete_outline_rounded,
            size: 18,
            color: AppColors.textPrimary,
          ),
          tooltip: 'Clear in-memory console (⌘K)',
          onPressed: cubit.clearConsole,
        ),
        IconButton(
          padding: const EdgeInsets.all(6),
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          icon: const Icon(
            Icons.delete_forever_outlined,
            size: 18,
            color: AppColors.statusError,
          ),
          tooltip: 'Clear device buffer (adb logcat -c)',
          onPressed: cubit.clearDeviceBuffer,
        ),
        const SizedBox(width: 6),
        Container(width: 1, height: 18, color: AppColors.borderSubtle),
        const SizedBox(width: 6),
        ElevatedButton.icon(
          onPressed: cubit.toggleFileRecording,
          icon: Icon(
            isRecording ? Icons.stop_rounded : Icons.fiber_manual_record,
            size: 14,
            color: isRecording ? Colors.white : AppColors.statusError,
          ),
          label: Text(
            isRecording
                ? 'Stop REC'
                : (isCompact ? 'Record' : 'Record to File'),
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
        ),
        const SizedBox(width: 6),
        OutlinedButton.icon(
          onPressed: onExportSnapshot,
          icon: const Icon(Icons.file_download_outlined, size: 14),
          label: isCompact
              ? const SizedBox.shrink()
              : const Text('Export', style: TextStyle(fontSize: 12)),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 8 : 10,
              vertical: 6,
            ),
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }
}
