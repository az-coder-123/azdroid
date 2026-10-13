import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wifi_desk/core/theme/app_colors.dart';
import 'package:wifi_desk/features/productivity/presentation/cubit/device_file_manager_cubit.dart';
import 'package:wifi_desk/features/productivity/presentation/cubit/device_file_manager_state.dart';

/// Top toolbar for the file explorer providing breadcrumb navigation,
/// instant search filtering, sort options, and bulk selection.
class DeviceFileManagerToolbar extends StatefulWidget {
  const DeviceFileManagerToolbar({
    super.key,
    required this.deviceSerial,
    required this.state,
  });

  final String deviceSerial;
  final DeviceFileManagerLoaded state;

  @override
  State<DeviceFileManagerToolbar> createState() =>
      _DeviceFileManagerToolbarState();
}

class _DeviceFileManagerToolbarState extends State<DeviceFileManagerToolbar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.state.searchQuery);
  }

  @override
  void didUpdateWidget(DeviceFileManagerToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.searchQuery != widget.state.searchQuery &&
        _searchController.text != widget.state.searchQuery) {
      _searchController.text = widget.state.searchQuery;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DeviceFileManagerCubit>();
    final canGoBack = widget.state.parentDirectory != null;
    final totalFiles = widget.state.visibleFiles
        .where((f) => !f.isDirectory)
        .length;
    final allSelected =
        totalFiles > 0 &&
        widget.state.selectedFiles.length >= totalFiles &&
        widget.state.visibleFiles
            .where((f) => !f.isDirectory)
            .every((f) => widget.state.selectedFiles.contains(f.path));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (canGoBack) ...[
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  tooltip: 'Go to parent folder',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 30,
                    minHeight: 30,
                  ),
                  onPressed: () => cubit.navigateUp(widget.deviceSerial),
                ),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  widget.state.currentDirectory,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 18),
                tooltip: 'Refresh folder',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                onPressed: () => cubit.refresh(widget.deviceSerial),
              ),
              const SizedBox(width: 4),
              _buildSortMenu(context, cubit),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Search files in this folder...',
                      hintStyle: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      prefixIcon: const Icon(Icons.search_rounded, size: 16),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 14),
                              onPressed: () {
                                _searchController.clear();
                                cubit.setSearchQuery('');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    onChanged: (val) => cubit.setSearchQuery(val),
                  ),
                ),
              ),
              if (totalFiles > 0) ...[
                const SizedBox(width: 10),
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => cubit.selectAll(!allSelected),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: allSelected,
                          onChanged: (val) => cubit.selectAll(val ?? false),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Select All ($totalFiles)',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSortMenu(BuildContext context, DeviceFileManagerCubit cubit) {
    return PopupMenuButton<FileSortOption>(
      icon: const Icon(Icons.sort_rounded, size: 18),
      tooltip: 'Sort files',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
      initialValue: widget.state.sortOption,
      onSelected: (option) => cubit.setSortOption(option),
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: FileSortOption.dateDesc,
          child: Text('Date (Newest First)'),
        ),
        PopupMenuItem(
          value: FileSortOption.dateAsc,
          child: Text('Date (Oldest First)'),
        ),
        PopupMenuItem(
          value: FileSortOption.sizeDesc,
          child: Text('Size (Largest First)'),
        ),
        PopupMenuItem(
          value: FileSortOption.sizeAsc,
          child: Text('Size (Smallest First)'),
        ),
        PopupMenuItem(
          value: FileSortOption.nameAsc,
          child: Text('Name (A to Z)'),
        ),
        PopupMenuItem(
          value: FileSortOption.nameDesc,
          child: Text('Name (Z to A)'),
        ),
      ],
    );
  }
}
