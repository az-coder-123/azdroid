import 'package:equatable/equatable.dart';
import 'package:desk_droid/features/productivity/domain/entities/file_transfer_entity.dart';

/// Base state for drag-and-drop file transfers and APK sideloading.
sealed class FileTransferState extends Equatable {
  const FileTransferState();

  @override
  List<Object?> get props => [];
}

/// Initial state when no transfers are pending.
class FileTransferInitial extends FileTransferState {
  const FileTransferInitial();
}

/// State emitted when files are actively being pushed or installed.
class FileTransferActive extends FileTransferState {
  const FileTransferActive({
    required this.currentTransfer,
    this.completedCount = 0,
    this.totalCount = 1,
  });

  final FileTransferEntity currentTransfer;
  final int completedCount;
  final int totalCount;

  @override
  List<Object?> get props => [currentTransfer, completedCount, totalCount];
}

/// State emitted upon successfully completing a transfer or APK install.
class FileTransferSuccess extends FileTransferState {
  const FileTransferSuccess({required this.completedTransfer});

  final FileTransferEntity completedTransfer;

  @override
  List<Object?> get props => [completedTransfer];
}

/// State emitted upon failure of a transfer.
class FileTransferFailure extends FileTransferState {
  const FileTransferFailure({
    required this.failedTransfer,
    required this.errorMessage,
  });

  final FileTransferEntity failedTransfer;
  final String errorMessage;

  @override
  List<Object?> get props => [failedTransfer, errorMessage];
}
