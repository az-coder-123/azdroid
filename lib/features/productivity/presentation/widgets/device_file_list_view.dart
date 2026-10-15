import 'package:flutter/material.dart';
import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/features/productivity/domain/entities/remote_file_entity.dart';
import 'package:desk_droid/features/productivity/presentation/cubit/device_file_manager_state.dart';

/// List view displaying remote Android directory contents with checkboxes and vibrant file icons.
class DeviceFileListView extends StatelessWidget {
  const DeviceFileListView({
    super.key,
    required this.state,
    required this.deviceSerial,
    required this.onOpenFolder,
    required this.onToggleSelection,
    required this.onRetry,
  });

  final DeviceFileManagerState state;
  final String deviceSerial;
  final ValueChanged<String> onOpenFolder;
  final ValueChanged<String> onToggleSelection;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state is DeviceFileManagerLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is DeviceFileManagerError) {
      final err = state as DeviceFileManagerError;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.statusError,
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                err.message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (state is DeviceFileManagerLoaded) {
      final loaded = state as DeviceFileManagerLoaded;
      final visible = loaded.visibleFiles;

      if (visible.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  loaded.searchQuery.isNotEmpty
                      ? Icons.search_off_rounded
                      : Icons.folder_open_rounded,
                  size: 40,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 12),
                Text(
                  loaded.searchQuery.isNotEmpty
                      ? 'No files matching "${loaded.searchQuery}"'
                      : 'No files in this folder.',
                  style: const TextStyle(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }

      return ListView.separated(
        itemCount: visible.length,
        separatorBuilder: (_, _) =>
            const Divider(height: 1, color: AppColors.border),
        itemBuilder: (context, index) {
          final item = visible[index];
          final isSelected = loaded.selectedFiles.contains(item.path);

          return ListTile(
            dense: true,
            leading: Icon(
              _getFileIcon(item),
              color: _getFileColor(item),
              size: 22,
            ),
            title: Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: item.isDirectory
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
            subtitle: Text(
              '${item.formattedSize} ${item.modifiedDate != null ? "• ${item.modifiedDate}" : ""}',
              style: const TextStyle(fontSize: 11),
            ),
            trailing: item.isDirectory
                ? const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                  )
                : Checkbox(
                    value: isSelected,
                    onChanged: (_) => onToggleSelection(item.path),
                  ),
            onTap: () {
              if (item.isDirectory) {
                onOpenFolder('${item.path}/');
              } else {
                onToggleSelection(item.path);
              }
            },
          );
        },
      );
    }

    return const SizedBox.shrink();
  }

  IconData _getFileIcon(RemoteFileEntity item) {
    if (item.isDirectory) return Icons.folder_rounded;
    if (item.isImage) return Icons.image_rounded;
    if (item.isVideo) return Icons.video_file_rounded;
    if (item.isAudio) return Icons.audio_file_rounded;
    if (item.isApk) return Icons.android_rounded;
    return Icons.insert_drive_file_rounded;
  }

  Color _getFileColor(RemoteFileEntity item) {
    if (item.isDirectory) return AppColors.accentLight;
    if (item.isImage) return const Color(0xFFC084FC); // Purple
    if (item.isVideo) return const Color(0xFF60A5FA); // Blue
    if (item.isAudio) return const Color(0xFFFBBF24); // Amber
    if (item.isApk) return const Color(0xFF4ADE80); // Green
    return AppColors.textSecondary;
  }
}
