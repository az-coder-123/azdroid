import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:desk_droid/core/constants/productivity_constants.dart';
import 'package:desk_droid/core/di/injection.dart';
import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/core/theme/app_typography.dart';
import 'package:desk_droid/features/productivity/presentation/cubit/device_file_manager_cubit.dart';
import 'package:desk_droid/features/productivity/presentation/cubit/device_file_manager_state.dart';
import 'package:desk_droid/features/productivity/presentation/widgets/device_file_list_view.dart';
import 'package:desk_droid/features/productivity/presentation/widgets/device_file_manager_toolbar.dart';

/// Modal dialog allowing users to browse, search, and download Android files to macOS Finder.
class DeviceFileManagerDialog extends StatefulWidget {
  const DeviceFileManagerDialog({super.key, required this.deviceSerial});

  final String deviceSerial;

  /// Shows the [DeviceFileManagerDialog].
  static Future<void> show(BuildContext context, String deviceSerial) =>
      showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (_) => BlocProvider<DeviceFileManagerCubit>(
          create: (_) => sl<DeviceFileManagerCubit>(),
          child: DeviceFileManagerDialog(deviceSerial: deviceSerial),
        ),
      );

  @override
  State<DeviceFileManagerDialog> createState() =>
      _DeviceFileManagerDialogState();
}

class _DeviceFileManagerDialogState extends State<DeviceFileManagerDialog> {
  static const _quickFolders = [
    ('Downloads', ProductivityConstants.defaultRemoteDownloadDir),
    ('Camera', ProductivityConstants.defaultRemoteCameraDir),
    ('Screenshots', ProductivityConstants.defaultRemoteScreenshotsDir),
    ('Movies', '/sdcard/Movies/'),
  ];

  @override
  void initState() {
    super.initState();
    context.read<DeviceFileManagerCubit>().loadDirectory(
      widget.deviceSerial,
      directory: ProductivityConstants.defaultRemoteDownloadDir,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: const BorderSide(color: AppColors.border),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 720,
          maxHeight: 620,
          minWidth: 440,
        ),
        child: Column(
          children: [
            _buildHeader(context),
            _buildQuickFolderBar(context),
            BlocBuilder<DeviceFileManagerCubit, DeviceFileManagerState>(
              builder: (context, state) => state is DeviceFileManagerLoaded
                  ? DeviceFileManagerToolbar(
                      deviceSerial: widget.deviceSerial,
                      state: state,
                    )
                  : const SizedBox.shrink(),
            ),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child:
                  BlocBuilder<DeviceFileManagerCubit, DeviceFileManagerState>(
                    builder: (context, state) {
                      final cubit = context.read<DeviceFileManagerCubit>();
                      return DeviceFileListView(
                        state: state,
                        deviceSerial: widget.deviceSerial,
                        onOpenFolder: (dir) => cubit.loadDirectory(
                          widget.deviceSerial,
                          directory: dir,
                        ),
                        onToggleSelection: cubit.toggleFileSelection,
                        onRetry: () => cubit.loadDirectory(widget.deviceSerial),
                      );
                    },
                  ),
            ),
            const Divider(height: 1, color: AppColors.border),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
      child: Row(
        children: [
          const Icon(
            Icons.folder_shared_rounded,
            color: AppColors.accentLight,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Android File Explorer',
              style: AppTypography.title.copyWith(fontSize: 16),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFolderBar(BuildContext context) {
    return BlocBuilder<DeviceFileManagerCubit, DeviceFileManagerState>(
      builder: (context, state) {
        final currentDir = state is DeviceFileManagerLoaded
            ? state.currentDirectory
            : (state is DeviceFileManagerLoading ? state.currentDirectory : '');
        final extPath = state is DeviceFileManagerLoaded
            ? state.externalStoragePath
            : null;
        final folders = [..._quickFolders, ('SD Card', extPath ?? '/storage/')];

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Row(
            children: folders.map((folder) {
              final isSelected =
                  currentDir == folder.$2 ||
                  (folder.$1 == 'SD Card' &&
                      currentDir.startsWith('/storage/') &&
                      !currentDir.startsWith('/storage/emulated'));
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilterChip(
                  avatar: folder.$1 == 'SD Card'
                      ? const Icon(Icons.sd_card_rounded, size: 16)
                      : null,
                  label: Text(folder.$1),
                  selected: isSelected,
                  onSelected: (_) {
                    final cubit = context.read<DeviceFileManagerCubit>();
                    if (folder.$1 == 'SD Card') {
                      cubit.openExternalStorage(widget.deviceSerial);
                    } else {
                      cubit.loadDirectory(
                        widget.deviceSerial,
                        directory: folder.$2,
                      );
                    }
                  },
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildFooter(BuildContext context) {
    return BlocBuilder<DeviceFileManagerCubit, DeviceFileManagerState>(
      builder: (context, state) {
        final count = state is DeviceFileManagerLoaded
            ? state.selectedFiles.length
            : 0;
        final sizeText =
            state is DeviceFileManagerLoaded &&
                state.formattedSelectedSize.isNotEmpty
            ? ' (${state.formattedSelectedSize})'
            : '';
        final isDownloading =
            state is DeviceFileManagerLoaded && state.isDownloading;
        final statusMsg = state is DeviceFileManagerLoaded
            ? state.statusMessage
            : null;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  statusMsg ??
                      (count > 0
                          ? '$count file(s) selected$sizeText'
                          : 'Select files to download'),
                  style: statusMsg != null
                      ? const TextStyle(
                          fontSize: 12,
                          color: AppColors.statusSuccess,
                        )
                      : AppTypography.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    context.read<DeviceFileManagerCubit>().openInFinder(),
                icon: const Icon(Icons.folder_open_rounded, size: 16),
                label: const Text('Open Downloads'),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: count > 0 && !isDownloading
                    ? () => context
                          .read<DeviceFileManagerCubit>()
                          .downloadSelected(widget.deviceSerial)
                    : null,
                icon: isDownloading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download_rounded, size: 16),
                label: Text(
                  isDownloading ? 'Downloading...' : 'Download to Mac',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
