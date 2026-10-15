import 'package:equatable/equatable.dart';
import 'package:wifi_desk/features/logging/domain/entities/device_log_entry.dart';
import 'package:wifi_desk/features/logging/domain/entities/log_level.dart';

/// Filter parameters applied to incoming Android log streams.
class LogFilterCriteria extends Equatable {
  const LogFilterCriteria({
    this.selectedLevels = const {},
    this.textQuery = '',
    this.isRegex = false,
    this.caseSensitive = false,
    this.tagFilter = '',
    this.pidFilter,
    this.bookmarksOnly = false,
    this.excludeTags = const {},
  });

  /// Set of active log levels to display. If empty, all levels are allowed.
  final Set<LogLevel> selectedLevels;

  /// General text search across message, tag, or raw payload.
  final String textQuery;

  /// Whether [textQuery] should be evaluated as a regular expression.
  final bool isRegex;

  /// Whether text search is case sensitive.
  final bool caseSensitive;

  /// Specific log tag filter (e.g. 'ActivityManager', 'AudioFlinger').
  final String tagFilter;

  /// Specific process ID filter.
  final int? pidFilter;

  /// Whether to only show bookmarked/starred entries.
  final bool bookmarksOnly;

  /// Set of tags to exclude/suppress from output.
  final Set<String> excludeTags;

  /// Evaluates whether an entry passes the current filter criteria.
  bool matches(DeviceLogEntry entry, {Set<int>? bookmarkedIds}) {
    // 0. Bookmarks check
    if (bookmarksOnly && !(bookmarkedIds?.contains(entry.id) ?? false)) {
      return false;
    }

    // 1. Excluded tags check
    if (excludeTags.isNotEmpty) {
      final entryTag = caseSensitive
          ? entry.tag.trim()
          : entry.tag.trim().toLowerCase();
      for (final ex in excludeTags) {
        final target = caseSensitive ? ex.trim() : ex.trim().toLowerCase();
        if (target.isNotEmpty && entryTag == target) {
          return false;
        }
      }
    }

    // 2. Level check
    if (selectedLevels.isNotEmpty && !selectedLevels.contains(entry.level)) {
      return false;
    }

    // 2. PID check
    if (pidFilter != null && entry.pid != pidFilter) {
      return false;
    }

    // 3. Tag filter check
    if (tagFilter.trim().isNotEmpty) {
      final targetTag = caseSensitive
          ? tagFilter.trim()
          : tagFilter.trim().toLowerCase();
      final entryTag = caseSensitive ? entry.tag : entry.tag.toLowerCase();
      if (!entryTag.contains(targetTag)) {
        return false;
      }
    }

    // 4. General search text query check
    final query = textQuery.trim();
    if (query.isNotEmpty) {
      if (isRegex) {
        try {
          final regex = RegExp(query, caseSensitive: caseSensitive);
          return regex.hasMatch(entry.message) || regex.hasMatch(entry.tag);
        } catch (_) {
          return false;
        }
      } else {
        final q = caseSensitive ? query : query.toLowerCase();
        final msg = caseSensitive ? entry.message : entry.message.toLowerCase();
        final tag = caseSensitive ? entry.tag : entry.tag.toLowerCase();
        if (!msg.contains(q) && !tag.contains(q)) {
          return false;
        }
      }
    }

    return true;
  }

  LogFilterCriteria copyWith({
    Set<LogLevel>? selectedLevels,
    String? textQuery,
    bool? isRegex,
    bool? caseSensitive,
    String? tagFilter,
    int? Function()? pidFilter,
    bool? bookmarksOnly,
    Set<String>? excludeTags,
  }) {
    return LogFilterCriteria(
      selectedLevels: selectedLevels ?? this.selectedLevels,
      textQuery: textQuery ?? this.textQuery,
      isRegex: isRegex ?? this.isRegex,
      caseSensitive: caseSensitive ?? this.caseSensitive,
      tagFilter: tagFilter ?? this.tagFilter,
      pidFilter: pidFilter != null ? pidFilter() : this.pidFilter,
      bookmarksOnly: bookmarksOnly ?? this.bookmarksOnly,
      excludeTags: excludeTags ?? this.excludeTags,
    );
  }

  @override
  List<Object?> get props => [
    selectedLevels,
    textQuery,
    isRegex,
    caseSensitive,
    tagFilter,
    pidFilter,
    bookmarksOnly,
    excludeTags,
  ];
}
