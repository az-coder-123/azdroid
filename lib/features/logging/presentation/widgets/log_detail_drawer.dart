import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/features/logging/domain/entities/device_log_entry.dart';
import 'package:desk_droid/features/logging/presentation/widgets/log_detail_drawer_header.dart';
import 'package:desk_droid/features/logging/presentation/widgets/log_stack_trace_view.dart';

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

    return Container(
      height: 220,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LogDetailDrawerHeader(
            entry: entry,
            isJsonFormatted: _isJsonFormatted,
            hasJsonPayload: _hasJsonPayload,
            onToggleJsonFormat: () =>
                setState(() => _isJsonFormatted = !_isJsonFormatted),
            isBookmarked: widget.isBookmarked,
            onToggleBookmark: widget.onToggleBookmark,
            onExcludeTag: widget.onExcludeTag,
            onCopyMessage: () {
              final text = _isJsonFormatted
                  ? _formatJsonIfPossible(entry.message)
                  : entry.message;
              Clipboard.setData(ClipboardData(text: text));
            },
            onCopyRawLine: () {
              Clipboard.setData(ClipboardData(text: entry.rawLine));
            },
            onClose: widget.onClose,
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
