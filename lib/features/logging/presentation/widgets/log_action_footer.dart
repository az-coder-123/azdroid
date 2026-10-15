import 'package:flutter/material.dart';
import 'package:wifi_desk/core/theme/app_colors.dart';
import 'package:wifi_desk/features/logging/domain/entities/log_file_recording_status.dart';
import 'package:wifi_desk/features/logging/presentation/widgets/log_footer_actions.dart';

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 650;
        final isNarrow = constraints.maxWidth < 500;

        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.borderSubtle)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 6.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Telemetry & Active REC Badge
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isNarrow
                              ? '$filteredEntries / $totalEntries lines'
                              : 'Showing $filteredEntries of $totalEntries lines',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (recordingStatus.isRecording) ...[
                          const SizedBox(width: 10),
                          _buildRecordingStatusBadge(),
                        ],
                      ],
                    ),
                    const SizedBox(width: 16),

                    // Actions Cluster
                    LogFooterActions(
                      isPaused: isPaused,
                      autoScroll: autoScroll,
                      softWrap: softWrap,
                      recordingStatus: recordingStatus,
                      isCompact: isCompact,
                      onExportSnapshot: onExportSnapshot,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecordingStatusBadge() {
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
}
