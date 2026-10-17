import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/features/logging/domain/entities/log_filter_criteria.dart';
import 'package:desk_droid/features/logging/domain/entities/log_level.dart';
import 'package:desk_droid/features/logging/presentation/cubit/device_log_cubit.dart';
import 'package:desk_droid/features/logging/presentation/utils/log_level_colors.dart';
import 'package:desk_droid/features/logging/presentation/widgets/log_exclude_tags_bar.dart';
import 'package:desk_droid/features/logging/presentation/widgets/log_filter_chips.dart';
import 'package:desk_droid/features/logging/presentation/widgets/log_pid_filter_input.dart';
import 'package:desk_droid/features/logging/presentation/widgets/log_preset_dropdown.dart';
import 'package:desk_droid/features/logging/presentation/widgets/log_tag_filter_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Top filtering toolbar providing level toggles, search text, regex, and tag/pid filters.
class LogFilterBar extends StatefulWidget {
  const LogFilterBar({
    super.key,
    required this.filter,
    this.tagCounts = const {},
    this.pidCounts = const {},
    this.pidPrimaryTags = const {},
    this.searchFocusNode,
  });

  final LogFilterCriteria filter;
  final Map<String, int> tagCounts;
  final Map<int, int> pidCounts;
  final Map<int, String> pidPrimaryTags;
  final FocusNode? searchFocusNode;

  @override
  State<LogFilterBar> createState() => _LogFilterBarState();
}

class _LogFilterBarState extends State<LogFilterBar> {
  late final TextEditingController _searchController;
  late final TextEditingController _tagController;
  late final TextEditingController _pidController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.filter.textQuery);
    _tagController = TextEditingController(text: widget.filter.tagFilter);
    _pidController = TextEditingController(
      text: widget.filter.pidFilter != null
          ? widget.filter.pidFilter.toString()
          : '',
    );
  }

  @override
  void didUpdateWidget(covariant LogFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filter.textQuery != _searchController.text &&
        !_searchController.value.isComposingRangeValid) {
      _searchController.text = widget.filter.textQuery;
    }
    if (widget.filter.tagFilter != _tagController.text &&
        !_tagController.value.isComposingRangeValid) {
      _tagController.text = widget.filter.tagFilter;
    }
    final currentPidStr = widget.filter.pidFilter?.toString() ?? '';
    if (currentPidStr != _pidController.text &&
        !_pidController.value.isComposingRangeValid) {
      _pidController.text = currentPidStr;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tagController.dispose();
    _pidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DeviceLogCubit>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Severity level filters & Mode toggles
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                LogFilterChip(
                  label: 'All',
                  isSelected: widget.filter.selectedLevels.isEmpty,
                  color: AppColors.accent,
                  onTap: () => cubit.updateFilter(
                    widget.filter.copyWith(selectedLevels: const {}),
                  ),
                ),
                const SizedBox(width: 6),
                for (final l in LogLevel.values.where(
                  (v) => v != LogLevel.unknown,
                )) ...[
                  LogFilterChip(
                    label: '${l.code} ${l.label}',
                    isSelected: widget.filter.selectedLevels.contains(l),
                    color: l.color,
                    onTap: () => cubit.toggleLevel(l),
                  ),
                  const SizedBox(width: 6),
                ],
                const SizedBox(width: 8),
                LogOptionToggle(
                  label: '.*',
                  tooltip: 'Regex mode',
                  isActive: widget.filter.isRegex,
                  onTap: cubit.toggleRegex,
                ),
                const SizedBox(width: 4),
                LogOptionToggle(
                  label: 'Aa',
                  tooltip: 'Case sensitive',
                  isActive: widget.filter.caseSensitive,
                  onTap: cubit.toggleCaseSensitive,
                ),
                const SizedBox(width: 8),
                LogBookmarkFilterChip(
                  isActive: widget.filter.bookmarksOnly,
                  onTap: cubit.toggleBookmarksOnly,
                ),
                const SizedBox(width: 8),
                LogPresetDropdown(
                  currentFilter: widget.filter,
                  onPresetSelected: (preset) {
                    cubit.updateFilter(preset.criteria);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Row 2: Search query, Tag, and PID inputs
          Row(
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 32,
                  child: TextField(
                    controller: _searchController,
                    focusNode: widget.searchFocusNode,
                    onChanged: cubit.updateSearch,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textPrimary,
                    ),
                    decoration: _inputDecoration(
                      hint: 'Search message, exception, stack trace... (⌘F)',
                      prefixIcon: Icons.search,
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 14),
                              onPressed: () {
                                _searchController.clear();
                                cubit.updateSearch('');
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 32,
                  child: LogTagFilterInput(
                    controller: _tagController,
                    tagCounts: widget.tagCounts,
                    onChanged: (tag) => cubit.updateFilter(
                      widget.filter.copyWith(tagFilter: tag),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 125,
                height: 32,
                child: LogPidFilterInput(
                  controller: _pidController,
                  pidCounts: widget.pidCounts,
                  pidPrimaryTags: widget.pidPrimaryTags,
                  onChanged: (pid) => cubit.updateFilter(
                    widget.filter.copyWith(pidFilter: () => pid),
                  ),
                ),
              ),
            ],
          ),
          if (widget.filter.excludeTags.isNotEmpty)
            LogExcludeTagsBar(
              excludeTags: widget.filter.excludeTags,
              availableTags: widget.tagCounts,
            ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, size: 16, color: AppColors.textSecondary)
          : null,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      filled: true,
      fillColor: AppColors.surfaceElevated,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6.0),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6.0),
        borderSide: const BorderSide(color: AppColors.borderSubtle),
      ),
    );
  }
}
