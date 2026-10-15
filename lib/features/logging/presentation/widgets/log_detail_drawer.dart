import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wifi_desk/core/theme/app_colors.dart';
import 'package:wifi_desk/features/logging/domain/entities/device_log_entry.dart';
import 'package:wifi_desk/features/logging/presentation/widgets/log_level_badge.dart';
import 'package:wifi_desk/features/logging/presentation/widgets/log_stack_trace_view.dart';

/// Bottom inspection drawer displaying full log body, formatted stack traces,
/// or pretty-printed JSON payloads.
class LogDetailDrawer extends StatefulWidget {
  const LogDetailDrawer({
    super.key,
    required this.entry,
    required this.onClose,
    this.isBookmarked = false,
    this.onToggleBookmark,
    this.onExcludeTag,
  });

  final DeviceLogEntry entry;
  final VoidCallback onClose;
  final bool isBookmarked;
  final VoidCallback? onToggleBookmark;
  final VoidCallback? onExcludeTag;

  @override
  State<LogDetailDrawer> createState() => _LogDetailDrawerState();
}

class _LogDetailDrawerState extends State<LogDetailDrawer> {
  bool _isJsonFormatted = false;

  bool get _hasJsonPayload {
    final trimmed = widget.entry.message.trim();
    return (trimmed.startsWith('{') && trimmed.endsWith('}')) ||
        (trimmed.startsWith('[') && trimmed.endsWith(']'));
  }

  String _formatJsonIfPossible(String raw) {
    try {
      final decoded = jsonDecode(raw.trim());
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(decoded);
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final t = entry.timestamp;
    final timeStr =
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:'
        '${t.second.toString().padLeft(2, '0')}.${t.millisecond.toString().padLeft(3, '0')}';

    return Container(
      height: 220,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header toolbar
          Container(
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
                if (_hasJsonPayload) ...[
                  InkWell(
                    onTap: () =>
                        setState(() => _isJsonFormatted = !_isJsonFormatted),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _isJsonFormatted
                            ? AppColors.accent.withValues(alpha: 0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: _isJsonFormatted
                              ? AppColors.accent
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        _isJsonFormatted ? 'JSON: Formatted' : 'JSON: Raw',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _isJsonFormatted
                              ? AppColors.accent
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (widget.onToggleBookmark != null)
                  IconButton(
                    icon: Icon(
                      widget.isBookmarked
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 15,
                      color: widget.isBookmarked
                          ? AppColors.statusWarning
                          : AppColors.textSecondary,
                    ),
                    tooltip: widget.isBookmarked
                        ? 'Unstar this log'
                        : 'Star this log',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 26,
                      minHeight: 26,
                    ),
                    onPressed: widget.onToggleBookmark,
                  ),
                if (widget.onExcludeTag != null)
                  IconButton(
                    icon: const Icon(
                      Icons.block_rounded,
                      size: 14,
                      color: AppColors.statusError,
                    ),
                    tooltip: 'Exclude tag "${widget.entry.tag}"',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 26,
                      minHeight: 26,
                    ),
                    onPressed: widget.onExcludeTag,
                  ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 14),
                  tooltip: 'Copy Message Only',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 26,
                    minHeight: 26,
                  ),
                  onPressed: () {
                    final text = _isJsonFormatted
                        ? _formatJsonIfPossible(entry.message)
                        : entry.message;
                    Clipboard.setData(ClipboardData(text: text));
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.data_object_rounded, size: 14),
                  tooltip: 'Copy Raw Logcat Line',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 26,
                    minHeight: 26,
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: entry.rawLine));
                  },
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 16),
                  tooltip: 'Close Inspector',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 26,
                    minHeight: 26,
                  ),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: _buildBodyContent(entry.message),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent(String message) {
    if (_isJsonFormatted && _hasJsonPayload) {
      final formatted = _formatJsonIfPossible(message);
      return SelectableText(
        formatted,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 11.5,
          height: 1.4,
          color: AppColors.accent,
        ),
      );
    }

    final isStackTrace =
        message.contains('\tat ') ||
        message.contains('Exception') ||
        message.contains('Caused by:');

    if (isStackTrace) {
      return LogStackTraceView(message: message);
    }

    return SelectableText(
      message,
      style: const TextStyle(
        fontFamily: 'monospace',
        fontSize: 11.5,
        height: 1.4,
        color: AppColors.textPrimary,
      ),
    );
  }
}
