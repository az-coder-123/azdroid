import 'package:desk_droid/features/logging/domain/entities/log_filter_criteria.dart';
import 'package:desk_droid/features/logging/domain/entities/log_level.dart';
import 'package:desk_droid/features/logging/presentation/cubit/device_log_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Mixin encapsulating log filtering, bookmarking, and search criteria operations
/// for [Cubit<DeviceLogState>].
mixin DeviceLogFilterMixin on Cubit<DeviceLogState> {
  /// Toggles star/bookmark on an entry ID.
  void toggleBookmark(int id) {
    final current = state;
    if (current is! DeviceLogStreaming) return;
    final updated = Set<int>.from(current.bookmarkedIds);
    updated.contains(id) ? updated.remove(id) : updated.add(id);
    final filtered = current.allEntries
        .where((e) => current.filter.matches(e, bookmarkedIds: updated))
        .toList();
    emit(current.copyWith(bookmarkedIds: updated, filteredEntries: filtered));
  }

  /// Toggles filtering only bookmarked/starred entries.
  void toggleBookmarksOnly() {
    final current = state;
    if (current is! DeviceLogStreaming) return;
    updateFilter(
      current.filter.copyWith(bookmarksOnly: !current.filter.bookmarksOnly),
    );
  }

  /// Adds a tag to the excluded tags set.
  void excludeTag(String tag) {
    final current = state;
    if (current is! DeviceLogStreaming || tag.trim().isEmpty) return;
    final updated = Set<String>.from(current.filter.excludeTags)
      ..add(tag.trim());
    updateFilter(current.filter.copyWith(excludeTags: updated));
  }

  /// Removes a tag from the excluded tags set.
  void removeExcludeTag(String tag) {
    final current = state;
    if (current is! DeviceLogStreaming) return;
    final updated = Set<String>.from(current.filter.excludeTags)
      ..remove(tag.trim());
    updateFilter(current.filter.copyWith(excludeTags: updated));
  }

  /// Clears all excluded tags.
  void clearExcludeTags() {
    final current = state;
    if (current is! DeviceLogStreaming) return;
    updateFilter(current.filter.copyWith(excludeTags: const {}));
  }

  /// Updates active filter criteria and re-evaluates visible logs.
  void updateFilter(LogFilterCriteria newFilter) {
    final current = state;
    if (current is! DeviceLogStreaming) return;
    final filtered = current.allEntries
        .where(
          (e) => newFilter.matches(e, bookmarkedIds: current.bookmarkedIds),
        )
        .toList();
    emit(current.copyWith(filter: newFilter, filteredEntries: filtered));
  }

  /// Toggles a specific severity level.
  void toggleLevel(LogLevel level) {
    final current = state;
    if (current is! DeviceLogStreaming) return;
    final levels = Set<LogLevel>.from(current.filter.selectedLevels);
    levels.contains(level) ? levels.remove(level) : levels.add(level);
    updateFilter(current.filter.copyWith(selectedLevels: levels));
  }

  /// Updates search text query.
  void updateSearch(String query) {
    final current = state;
    if (current is DeviceLogStreaming) {
      updateFilter(current.filter.copyWith(textQuery: query));
    }
  }

  /// Toggles regex evaluation mode.
  void toggleRegex() {
    final current = state;
    if (current is DeviceLogStreaming) {
      updateFilter(current.filter.copyWith(isRegex: !current.filter.isRegex));
    }
  }

  /// Toggles case-sensitivity for search and tags.
  void toggleCaseSensitive() {
    final current = state;
    if (current is DeviceLogStreaming) {
      updateFilter(
        current.filter.copyWith(caseSensitive: !current.filter.caseSensitive),
      );
    }
  }
}
