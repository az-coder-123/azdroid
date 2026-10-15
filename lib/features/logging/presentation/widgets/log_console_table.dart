import 'package:flutter/material.dart';
import 'package:wifi_desk/core/theme/app_colors.dart';
import 'package:wifi_desk/features/logging/domain/entities/device_log_entry.dart';
import 'package:wifi_desk/features/logging/presentation/widgets/log_console_row.dart';

/// Virtualized console log table rendering color-coded logcat entries with auto-scrolling.
class LogConsoleTable extends StatefulWidget {
  const LogConsoleTable({
    super.key,
    required this.entries,
    required this.autoScroll,
    required this.isPaused,
    required this.searchQuery,
    required this.onScrollToBottom,
    this.selectedEntry,
    this.onSelectEntry,
    this.bookmarkedIds = const {},
    this.onToggleBookmark,
    this.softWrap = false,
  });

  final List<DeviceLogEntry> entries;
  final bool autoScroll;
  final bool isPaused;
  final String searchQuery;
  final VoidCallback onScrollToBottom;
  final DeviceLogEntry? selectedEntry;
  final ValueChanged<DeviceLogEntry>? onSelectEntry;
  final Set<int> bookmarkedIds;
  final ValueChanged<int>? onToggleBookmark;
  final bool softWrap;

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
    final isReversed = widget.entries.length >= 25;

    if (widget.softWrap != oldWidget.softWrap &&
        (_isNearBottom || widget.autoScroll)) {
      _scrollToBottom(isReversed);
    } else if (widget.autoScroll && _isNearBottom && diff > 0) {
      _scrollToBottom(isReversed);
      _unseenNewCount = 0;
    } else if (!_isNearBottom && diff > 0) {
      setState(() {
        _unseenNewCount += diff;
      });
    }
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final isReversed = widget.entries.length >= 25;
    final bool nearBottom;
    if (isReversed) {
      nearBottom = _scrollController.position.pixels < 60;
    } else {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      nearBottom = (maxScroll - currentScroll) < 60;
    }

    if (nearBottom != _isNearBottom) {
      setState(() {
        _isNearBottom = nearBottom;
        if (nearBottom) _unseenNewCount = 0;
      });
    }
  }

  void _scrollToBottom(bool isReversed) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      if (isReversed) {
        if (_scrollController.position.pixels != 0.0) {
          _scrollController.jumpTo(0.0);
        }
      } else {
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

    final isReversed = widget.entries.length >= 25;

    return Stack(
      children: [
        Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          child: ListView.builder(
            key: ValueKey('log_table_${isReversed}_${widget.softWrap}'),
            controller: _scrollController,
            reverse: isReversed,
            itemCount: widget.entries.length,
            physics: const ClampingScrollPhysics(),
            itemExtent: widget.softWrap ? null : 26.0,
            itemBuilder: (context, index) {
              final entry = isReversed
                  ? widget.entries[widget.entries.length - 1 - index]
                  : widget.entries[index];
              return LogConsoleRow(
                entry: entry,
                isSelected: widget.selectedEntry?.id == entry.id,
                isBookmarked: widget.bookmarkedIds.contains(entry.id),
                softWrap: widget.softWrap,
                onTap: () => widget.onSelectEntry?.call(entry),
                onToggleBookmark: () => widget.onToggleBookmark?.call(entry.id),
              );
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
                  if (isReversed) {
                    _scrollController.animateTo(
                      0.0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                    );
                  } else {
                    _scrollToBottom(false);
                  }
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
}
