import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wifi_desk/core/theme/app_colors.dart';
import 'package:wifi_desk/features/logging/domain/entities/device_log_entry.dart';
import 'package:wifi_desk/features/logging/presentation/utils/log_search_highlighter.dart';
import 'package:wifi_desk/features/logging/presentation/widgets/log_level_badge.dart';

/// Single logcat row item rendering color-coded timestamp, PID:TID, level, tag,
/// message, and bookmark/copy actions.
class LogConsoleRow extends StatelessWidget {
  const LogConsoleRow({
    super.key,
    required this.entry,
    required this.isSelected,
    required this.isBookmarked,
    required this.softWrap,
    required this.onTap,
    required this.onToggleBookmark,
    this.searchQuery = '',
    this.caseSensitive = false,
    this.isRegex = false,
  });

  final DeviceLogEntry entry;
  final bool isSelected;
  final bool isBookmarked;
  final bool softWrap;
  final VoidCallback onTap;
  final VoidCallback onToggleBookmark;
  final String searchQuery;
  final bool caseSensitive;
  final bool isRegex;

  @override
  Widget build(BuildContext context) {
    final timeStr =
        '${entry.timestamp.hour.toString().padLeft(2, '0')}:'
        '${entry.timestamp.minute.toString().padLeft(2, '0')}:'
        '${entry.timestamp.second.toString().padLeft(2, '0')}.'
        '${entry.timestamp.millisecond.toString().padLeft(3, '0')}';

    return InkWell(
      onTap: onTap,
      hoverColor: AppColors.surfaceElevated.withValues(alpha: 0.6),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.18)
              : entry.level.rowBackgroundColor,
          border: isSelected
              ? const Border(
                  left: BorderSide(color: AppColors.accent, width: 3),
                )
              : null,
        ),
        padding: EdgeInsets.only(
          left: isSelected ? 9.0 : 12.0,
          right: 12.0,
          top: softWrap ? 5.0 : 0.0,
          bottom: softWrap ? 5.0 : 0.0,
        ),
        alignment: softWrap ? Alignment.topLeft : Alignment.centerLeft,
        child: Row(
          crossAxisAlignment: softWrap
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 84,
              child: Text(
                timeStr,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 76,
              child: Text(
                '${entry.pid}:${entry.tid}',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 6),
            LogLevelBadge(level: entry.level, compact: true),
            const SizedBox(width: 8),
            SizedBox(
              width: 120,
              child: Text.rich(
                TextSpan(
                  children: LogSearchHighlighter.buildSpans(
                    text: entry.tag,
                    query: searchQuery,
                    baseStyle: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: entry.level.color,
                    ),
                    highlightColor: AppColors.statusWarning,
                    caseSensitive: caseSensitive,
                    isRegex: isRegex,
                  ),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: LogSearchHighlighter.buildSpans(
                    text: entry.message,
                    query: searchQuery,
                    baseStyle: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: entry.level.color == AppColors.textSecondary
                          ? AppColors.textPrimary
                          : entry.level.color.withValues(alpha: 0.95),
                    ),
                    highlightColor: AppColors.statusWarning,
                    caseSensitive: caseSensitive,
                    isRegex: isRegex,
                  ),
                ),
                maxLines: softWrap ? 6 : 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: Icon(
                isBookmarked ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 14,
                color: isBookmarked
                    ? AppColors.statusWarning
                    : AppColors.textSecondary.withValues(alpha: 0.6),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              tooltip: isBookmarked ? 'Unstar line' : 'Star line',
              onPressed: onToggleBookmark,
            ),
            IconButton(
              icon: const Icon(
                Icons.copy_rounded,
                size: 12,
                color: AppColors.textSecondary,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              tooltip: 'Copy line',
              onPressed: () =>
                  Clipboard.setData(ClipboardData(text: entry.rawLine)),
            ),
          ],
        ),
      ),
    );
  }
}
