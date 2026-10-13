import 'package:equatable/equatable.dart';
import 'package:wifi_desk/features/productivity/domain/entities/remote_file_entity.dart';

/// Base state for the remote Android file manager.
abstract class DeviceFileManagerState extends Equatable {
  const DeviceFileManagerState();

  @override
  List<Object?> get props => [];
}

/// Initial uninitialized state.
class DeviceFileManagerInitial extends DeviceFileManagerState {
  const DeviceFileManagerInitial();
}

/// Directory contents currently being queried via ADB.
class DeviceFileManagerLoading extends DeviceFileManagerState {
  const DeviceFileManagerLoading({required this.currentDirectory});

  final String currentDirectory;

  @override
  List<Object?> get props => [currentDirectory];
}

/// Directory files loaded and displayed to the user.
class DeviceFileManagerLoaded extends DeviceFileManagerState {
  const DeviceFileManagerLoaded({
    required this.currentDirectory,
    required this.files,
    this.selectedFiles = const {},
    this.isDownloading = false,
    this.statusMessage,
  });

  final String currentDirectory;
  final List<RemoteFileEntity> files;
  final Set<String> selectedFiles;
  final bool isDownloading;
  final String? statusMessage;

  DeviceFileManagerLoaded copyWith({
    String? currentDirectory,
    List<RemoteFileEntity>? files,
    Set<String>? selectedFiles,
    bool? isDownloading,
    String? statusMessage,
    bool clearStatusMessage = false,
  }) {
    return DeviceFileManagerLoaded(
      currentDirectory: currentDirectory ?? this.currentDirectory,
      files: files ?? this.files,
      selectedFiles: selectedFiles ?? this.selectedFiles,
      isDownloading: isDownloading ?? this.isDownloading,
      statusMessage: clearStatusMessage
          ? null
          : (statusMessage ?? this.statusMessage),
    );
  }

  @override
  List<Object?> get props => [
    currentDirectory,
    files,
    selectedFiles,
    isDownloading,
    statusMessage,
  ];
}

/// Failure when querying directory or downloading files.
class DeviceFileManagerError extends DeviceFileManagerState {
  const DeviceFileManagerError({
    required this.message,
    required this.currentDirectory,
  });

  final String message;
  final String currentDirectory;

  @override
  List<Object?> get props => [message, currentDirectory];
}
