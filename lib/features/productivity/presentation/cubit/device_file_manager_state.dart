import 'package:desk_droid/features/productivity/domain/entities/remote_file_entity.dart';
import 'package:equatable/equatable.dart';

/// Available sorting criteria for the Android file explorer.
enum FileSortOption { nameAsc, nameDesc, dateDesc, dateAsc, sizeDesc, sizeAsc }

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
    this.searchQuery = '',
    this.sortOption = FileSortOption.nameAsc,
    this.externalStoragePath,
  });

  final String currentDirectory;
  final List<RemoteFileEntity> files;
  final Set<String> selectedFiles;
  final bool isDownloading;
  final String? statusMessage;
  final String searchQuery;
  final FileSortOption sortOption;
  final String? externalStoragePath;

  /// Returns total size in bytes of all currently selected files.
  int get selectedSizeBytes {
    int total = 0;
    for (final f in files) {
      if (selectedFiles.contains(f.path)) {
        total += f.sizeBytes;
      }
    }
    return total;
  }

  /// Returns human-readable size of selected files (e.g., '14.2 MB').
  String get formattedSelectedSize {
    if (selectedSizeBytes <= 0) return '';
    if (selectedSizeBytes < 1024) return '$selectedSizeBytes B';
    if (selectedSizeBytes < 1024 * 1024) {
      return '${(selectedSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    if (selectedSizeBytes < 1024 * 1024 * 1024) {
      return '${(selectedSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(selectedSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Returns parent directory path if the current folder is a subfolder.
  String? get parentDirectory {
    var norm = currentDirectory;
    if (norm.endsWith('/')) {
      norm = norm.substring(0, norm.length - 1);
    }
    if (norm.isEmpty || norm == '/storage') {
      return null;
    }
    if (norm == '/sdcard' ||
        norm == '/storage/emulated/0' ||
        norm == '/storage/emulated') {
      return '/storage/';
    }
    final lastSlash = norm.lastIndexOf('/');
    if (lastSlash <= 0) return '/storage/';
    return '${norm.substring(0, lastSlash)}/';
  }

  /// Returns filtered and sorted file list based on [searchQuery] and [sortOption].
  List<RemoteFileEntity> get visibleFiles {
    var result = files;
    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      result = result.where((f) => f.name.toLowerCase().contains(q)).toList();
    }

    final sorted = List<RemoteFileEntity>.from(result);
    sorted.sort((a, b) {
      if (a.isDirectory && !b.isDirectory) return -1;
      if (!a.isDirectory && b.isDirectory) return 1;
      switch (sortOption) {
        case FileSortOption.nameAsc:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case FileSortOption.nameDesc:
          return b.name.toLowerCase().compareTo(a.name.toLowerCase());
        case FileSortOption.dateDesc:
          return (b.modifiedDate ?? '').compareTo(a.modifiedDate ?? '');
        case FileSortOption.dateAsc:
          return (a.modifiedDate ?? '').compareTo(b.modifiedDate ?? '');
        case FileSortOption.sizeDesc:
          return b.sizeBytes.compareTo(a.sizeBytes);
        case FileSortOption.sizeAsc:
          return a.sizeBytes.compareTo(b.sizeBytes);
      }
    });
    return sorted;
  }

  DeviceFileManagerLoaded copyWith({
    String? currentDirectory,
    List<RemoteFileEntity>? files,
    Set<String>? selectedFiles,
    bool? isDownloading,
    String? statusMessage,
    String? searchQuery,
    FileSortOption? sortOption,
    String? externalStoragePath,
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
      searchQuery: searchQuery ?? this.searchQuery,
      sortOption: sortOption ?? this.sortOption,
      externalStoragePath: externalStoragePath ?? this.externalStoragePath,
    );
  }

  @override
  List<Object?> get props => [
    currentDirectory,
    files,
    selectedFiles,
    isDownloading,
    statusMessage,
    searchQuery,
    sortOption,
    externalStoragePath,
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
