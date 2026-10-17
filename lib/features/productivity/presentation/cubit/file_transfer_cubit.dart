import 'dart:async';

import 'package:desk_droid/core/constants/feedback_durations.dart';
import 'package:desk_droid/core/constants/productivity_constants.dart';
import 'package:desk_droid/core/platform/file_picker/host_file_picker.dart';
import 'package:desk_droid/core/services/local_file_system_gateway.dart';
import 'package:desk_droid/features/productivity/domain/entities/file_transfer_entity.dart';
import 'package:desk_droid/features/productivity/domain/repositories/file_transfer_repository.dart';
import 'package:desk_droid/features/productivity/presentation/cubit/file_transfer_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;

/// Cubit managing drag-and-drop file transfers and APK sideloading.
class FileTransferCubit extends Cubit<FileTransferState> {
  FileTransferCubit({
    required this.repository,
    this.autoResetDuration = FeedbackDurations.statusBanner,
    this._fileSystem = const IoLocalFileSystemGateway(),
    this._filePicker = const FileSelectorHostFilePicker(),
  }) : super(const FileTransferInitial());

  final FileTransferRepository repository;
  final LocalFileSystemGateway _fileSystem;
  final HostFilePicker _filePicker;

  /// Opens the native file picker and transfers the chosen files, if any.
  Future<void> pickAndTransferFiles(String deviceSerial) async {
    final files = await _filePicker.pickFiles();
    if (files.isNotEmpty && !isClosed) {
      await transferFiles(deviceSerial, files);
    }
  }

  final Duration? autoResetDuration;
  Timer? _autoResetTimer;

  /// Resets state back to initial idle.
  void reset() {
    _autoResetTimer?.cancel();
    emit(const FileTransferInitial());
  }

  @override
  Future<void> close() {
    _autoResetTimer?.cancel();
    return super.close();
  }

  /// Pushes local files to the connected Android device.
  ///
  /// [paths] may contain files or directories; directories are expanded
  /// recursively into their contained files before transfer.
  Future<void> transferFiles(String deviceSerial, List<String> paths) async {
    final filePaths = _fileSystem.expandToFiles(paths);
    if (filePaths.isEmpty) return;

    final totalCount = filePaths.length;
    int completedCount = 0;

    for (final path in filePaths) {
      final fileName = p.basename(path);
      final isApk = path.toLowerCase().endsWith(
        ProductivityConstants.apkExtension,
      );

      final sizeBytes = _fileSystem.fileSizeOf(path);

      final transfer = FileTransferEntity(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        fileName: fileName,
        localPath: path,
        fileSizeBytes: sizeBytes,
        isApk: isApk,
        status: FileTransferStatus.inProgress,
      );

      if (!isClosed) {
        emit(
          FileTransferActive(
            currentTransfer: transfer,
            completedCount: completedCount,
            totalCount: totalCount,
          ),
        );
      }

      final bool success;
      if (isApk) {
        success = await repository.installApk(deviceSerial, path);
      } else {
        success = await repository.pushFile(deviceSerial, path);
      }

      if (success) {
        completedCount++;
        final updated = transfer.copyWith(
          status: FileTransferStatus.completed,
          progress: 1.0,
        );
        if (!isClosed) {
          emit(FileTransferSuccess(completedTransfer: updated));
          if (autoResetDuration != null) {
            _autoResetTimer?.cancel();
            _autoResetTimer = Timer(autoResetDuration!, () {
              if (!isClosed && state is FileTransferSuccess) {
                emit(const FileTransferInitial());
              }
            });
          }
        }
      } else {
        final failed = transfer.copyWith(
          status: FileTransferStatus.failed,
          errorMessage: isApk
              ? 'Failed to install APK on device.'
              : 'Failed to push file to Android Download directory.',
        );
        if (!isClosed) {
          emit(
            FileTransferFailure(
              failedTransfer: failed,
              errorMessage: failed.errorMessage!,
            ),
          );
        }
      }
    }
  }
}
