import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wifi_desk/core/theme/app_colors.dart';
import 'package:wifi_desk/features/logging/domain/entities/device_log_entry.dart';
import 'package:wifi_desk/features/logging/presentation/widgets/log_level_badge.dart';

/// Virtualized console log table rendering color-coded logcat entries with auto-scrolling.
class LogConsoleTable extends StatefulWidget {
  const LogConsoleTable({
    super.key,
    required this.entries,
    required this.autoScroll,
    required this.isPaused,
    required this.searchQuery,
    required this.onScrollToBottom,
  });

  final List<DeviceLogEntry> entries;
  final bool autoScroll;
  final bool isPaused;
  final String searchQuery;
  final VoidCallback onScrollToBottom;

  @override
  State<LogConsoleTable> createState() => _LogConsoleTableState();
}

class _LogConsoleTableState extends State<LogConsoleTable> {
  final ScrollController _scrollController = ScrollController();
  bool _isNearBottom = true;
  int _unseenNewCount = 0;
  int _prevEntryCount = 0;

  @override
  void initState() {
    super.initState();
    _prevEntryCount = widget.entries.length;
    _scrollController.addListener(_handleScroll);
  }

  @override
  void didUpdateWidget(covariant LogConsoleTable oldWidget) {
    super.didUpdateWidget(oldWidget);

    final diff = widget.entries.length - _prevEntryCount;
    _prevEntryCount = widget.entries.length;

    if (widget.autoScroll && _isNearBottom && diff > 0) {
      _scrollToEnd();
      _unseenNewCount = 0;
    } else if (!_isNearBottom && diff > 0) {
      setState(() {
        _unseenNewCount += diff;
      });
    }
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final nearBottom = (maxScroll - currentScroll) < 60;

    if (nearBottom != _isNearBottom) {
      setState(() {
        _isNearBottom = nearBottom;
        if (nearBottom) _unseenNewCount = 0;
      });
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.isPaused
                  ? Icons.pause_circle_outline
                  : Icons.terminal_rounded,
              size: 40,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              widget.isPaused
                  ? 'Console is paused. Resume to stream logs.'
                  : 'No log entries match the current filter criteria.',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        SelectionArea(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: widget.entries.length,
            physics: const ClampingScrollPhysics(),
            itemExtent: 26.0,
            itemBuilder: (context, index) {
              final entry = widget.entries[index];
              return _buildLogRow(entry);
            },
          ),
        ),

        // Floating jump to latest pill if user scrolled up
        if (!_isNearBottom && _unseenNewCount > 0)
          Positioned(
            bottom: 16,
            right: 24,
            child: Material(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(20),
              elevation: 4,
              child: InkWell(
                onTap: () {
                  _scrollToEnd();
                  widget.onScrollToBottom();
                  setState(() => _unseenNewCount = 0);
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.arrow_downward,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Jump to latest (+$_unseenNewCount)',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLogRow(DeviceLogEntry entry) {
    final timeStr =
        '${entry.timestamp.hour.toString().padLeft(2, '0')}:'
        '${entry.timestamp.minute.toString().padLeft(2, '0')}:'
        '${entry.timestamp.second.toString().padLeft(2, '0')}.'
        '${entry.timestamp.millisecond.toString().padLeft(3, '0')}';

    return Container(
      color: entry.level.rowBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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
            child: Text(
              entry.tag,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: entry.level.color,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              entry.message,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: entry.level.color == AppColors.textSecondary
                    ? AppColors.textPrimary
                    : entry.level.color.withValues(alpha: 0.95),
              ),
            ),
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
    );
  }
}
