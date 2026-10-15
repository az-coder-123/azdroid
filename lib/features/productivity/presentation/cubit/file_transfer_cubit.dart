import 'dart:async';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wifi_desk/core/constants/productivity_constants.dart';
import 'package:wifi_desk/features/productivity/domain/entities/file_transfer_entity.dart';
import 'package:wifi_desk/features/productivity/domain/repositories/file_transfer_repository.dart';
import 'package:wifi_desk/features/productivity/presentation/cubit/file_transfer_state.dart';

/// Cubit managing drag-and-drop file transfers and APK sideloading.
class FileTransferCubit extends Cubit<FileTransferState> {
  FileTransferCubit({
    required this.repository,
    this.autoResetDuration = const Duration(seconds: 4),
  }) : super(const FileTransferInitial());

  final FileTransferRepository repository;
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

  /// Processes and pushes a batch of local file paths to the connected Android device.
  Future<void> transferFiles(
    String deviceSerial,
    List<String> filePaths,
  ) async {
    if (filePaths.isEmpty) return;

    final totalCount = filePaths.length;
    int completedCount = 0;

    for (final path in filePaths) {
      final fileName = path.split('/').last;
      final isApk = path.toLowerCase().endsWith(
        ProductivityConstants.apkExtension,
      );

      int sizeBytes = 0;
      try {
        final f = File(path);
        if (f.existsSync()) {
          sizeBytes = f.lengthSync();
        }
      } catch (_) {}

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
