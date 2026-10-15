import 'dart:io';
import 'dart:ui';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/features/productivity/presentation/cubit/file_transfer_cubit.dart';

/// Wraps the viewport with a drag-and-drop listener detecting local files dropped from Finder.
class FileDropTargetOverlay extends StatefulWidget {
  const FileDropTargetOverlay({
    required this.deviceSerial,
    required this.child,
    super.key,
  });

  final String deviceSerial;
  final Widget child;

  @override
  State<FileDropTargetOverlay> createState() => _FileDropTargetOverlayState();
}

class _FileDropTargetOverlayState extends State<FileDropTargetOverlay> {
  bool _isDragging = false;

  List<String> _resolveFiles(List<String> rawPaths) {
    final results = <String>[];
    for (final path in rawPaths) {
      if (path.isEmpty) continue;
      final type = FileSystemEntity.typeSync(path);
      if (type == FileSystemEntityType.file) {
        results.add(path);
      } else if (type == FileSystemEntityType.directory) {
        try {
          final entities = Directory(path)
              .listSync(recursive: true, followLinks: false);
          for (final entity in entities) {
            if (entity is File) {
              results.add(entity.path);
            }
          }
        } catch (_) {}
      }
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      onDragDone: (detail) {
        setState(() => _isDragging = false);
        final rawPaths = detail.files.map((f) => f.path).toList();
        if (rawPaths.isEmpty) return;

        final resolved = _resolveFiles(rawPaths);
        if (resolved.isNotEmpty && mounted) {
          context.read<FileTransferCubit>().transferFiles(
            widget.deviceSerial,
            resolved,
          );
        }
      },
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          widget.child,
          if (_isDragging)
            Positioned.fill(
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.75),
                      border: Border.all(color: AppColors.accent, width: 2.5),
                    ),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 20,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.file_download_outlined,
                                color: AppColors.accentLight,
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Drop Files to Transfer',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Documents & media ➔ /sdcard/Download/\n.apk packages ➔ Auto-install on device',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
