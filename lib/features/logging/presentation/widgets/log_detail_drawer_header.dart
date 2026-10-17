import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/features/logging/domain/entities/device_log_entry.dart';
import 'package:desk_droid/features/logging/presentation/utils/log_level_colors.dart';
import 'package:desk_droid/features/logging/presentation/widgets/log_level_badge.dart';
import 'package:flutter/material.dart';

/// Top inspection toolbar for [LogDetailDrawer] providing metadata tags,
/// formatting toggles, bookmark actions, and clipboard copy operations.
class LogDetailDrawerHeader extends StatelessWidget {
  const LogDetailDrawerHeader({
    super.key,
    required this.entry,
    required this.isJsonFormatted,
    required this.hasJsonPayload,
    required this.onToggleJsonFormat,
    required this.isBookmarked,
    this.onToggleBookmark,
    this.onExcludeTag,
    required this.onCopyMessage,
    required this.onCopyRawLine,
    required this.onClose,
  });

  final DeviceLogEntry entry;
  final bool isJsonFormatted;
  final bool hasJsonPayload;
  final VoidCallback onToggleJsonFormat;
  final bool isBookmarked;
  final VoidCallback? onToggleBookmark;
  final VoidCallback? onExcludeTag;
  final VoidCallback onCopyMessage;
  final VoidCallback onCopyRawLine;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final t = entry.timestamp;
    final timeStr =
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:'
        '${t.second.toString().padLeft(2, '0')}.${t.millisecond.toString().padLeft(3, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                LogLevelBadge(level: entry.level, compact: true),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    entry.tag,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: entry.level.color,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${entry.pid}:${entry.tid}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  timeStr,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (hasJsonPayload) ...[
            InkWell(
              onTap: onToggleJsonFormat,
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isJsonFormatted
                      ? AppColors.accent.withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isJsonFormatted
                        ? AppColors.accent
                        : AppColors.border,
                  ),
                ),
                child: Text(
                  isJsonFormatted ? 'JSON: Formatted' : 'JSON: Raw',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isJsonFormatted
                        ? AppColors.accent
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          if (onToggleBookmark != null)
            IconButton(
              icon: Icon(
                isBookmarked ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 15,
                color: isBookmarked
                    ? AppColors.statusWarning
                    : AppColors.textSecondary,
              ),
              tooltip: isBookmarked ? 'Unstar this log' : 'Star this log',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
              onPressed: onToggleBookmark,
            ),
          if (onExcludeTag != null)
            IconButton(
              icon: const Icon(
                Icons.block_rounded,
                size: 14,
                color: AppColors.statusError,
              ),
              tooltip: 'Exclude tag "${entry.tag}"',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
              onPressed: onExcludeTag,
            ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 14),
            tooltip: 'Copy Message Only',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
            onPressed: onCopyMessage,
          ),
          IconButton(
            icon: const Icon(Icons.data_object_rounded, size: 14),
            tooltip: 'Copy Raw Logcat Line',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
            onPressed: onCopyRawLine,
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 16),
            tooltip: 'Close Inspector',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}
