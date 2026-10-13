import 'package:flutter_test/flutter_test.dart';
import 'package:wifi_desk/features/productivity/domain/entities/remote_file_entity.dart';
import 'package:wifi_desk/features/productivity/presentation/cubit/device_file_manager_state.dart';

void main() {
  group('DeviceFileManagerLoaded state helpers', () {
    const fileA = RemoteFileEntity(
      name: 'apple.png',
      path: '/sdcard/Download/apple.png',
      sizeBytes: 1024 * 1024 * 2, // 2 MB
      isDirectory: false,
      modifiedDate: '2026-01-01 10:00',
    );

    const fileB = RemoteFileEntity(
      name: 'banana.mp4',
      path: '/sdcard/Download/banana.mp4',
      sizeBytes: 1024 * 1024 * 50, // 50 MB
      isDirectory: false,
      modifiedDate: '2026-05-15 12:00',
    );

    const dirC = RemoteFileEntity(
      name: 'Camera',
      path: '/sdcard/Download/Camera',
      sizeBytes: 0,
      isDirectory: true,
      modifiedDate: '2026-03-01 09:00',
    );

    test('visibleFiles filters by searchQuery case-insensitively', () {
      const state = DeviceFileManagerLoaded(
        currentDirectory: '/sdcard/Download/',
        files: [dirC, fileA, fileB],
        searchQuery: 'apple',
      );

      final visible = state.visibleFiles;
      expect(visible.length, equals(1));
      expect(visible.first.name, equals('apple.png'));
    });

    test('visibleFiles sorts directories first then applies sortOption', () {
      // Sort by size descending
      const stateBySize = DeviceFileManagerLoaded(
        currentDirectory: '/sdcard/Download/',
        files: [fileA, dirC, fileB],
        sortOption: FileSortOption.sizeDesc,
      );
      final bySize = stateBySize.visibleFiles;
      expect(bySize[0].name, equals('Camera')); // directory first
      expect(bySize[1].name, equals('banana.mp4')); // 50 MB
      expect(bySize[2].name, equals('apple.png')); // 2 MB

      // Sort by date descending
      const stateByDate = DeviceFileManagerLoaded(
        currentDirectory: '/sdcard/Download/',
        files: [fileA, dirC, fileB],
        sortOption: FileSortOption.dateDesc,
      );
      final byDate = stateByDate.visibleFiles;
      expect(byDate[0].name, equals('Camera')); // directory first
      expect(byDate[1].name, equals('banana.mp4')); // 2026-05-15
      expect(byDate[2].name, equals('apple.png')); // 2026-01-01
    });

    test('selectedSizeBytes and formattedSelectedSize calculate correctly', () {
      const state = DeviceFileManagerLoaded(
        currentDirectory: '/sdcard/Download/',
        files: [fileA, fileB],
        selectedFiles: {
          '/sdcard/Download/apple.png',
          '/sdcard/Download/banana.mp4',
        },
      );

      expect(
        state.selectedSizeBytes,
        equals(fileA.sizeBytes + fileB.sizeBytes),
      );
      expect(state.formattedSelectedSize, equals('52.0 MB'));
    });

    test('parentDirectory resolves parent paths, navigates to /storage/, and null for /storage', () {
      const subState = DeviceFileManagerLoaded(
        currentDirectory: '/sdcard/Download/NearSend/',
        files: [],
      );
      expect(subState.parentDirectory, equals('/sdcard/Download/'));

      const sdcardState = DeviceFileManagerLoaded(
        currentDirectory: '/sdcard/',
        files: [],
      );
      expect(sdcardState.parentDirectory, equals('/storage/'));

      const rootState = DeviceFileManagerLoaded(
        currentDirectory: '/storage/',
        files: [],
      );
      expect(rootState.parentDirectory, isNull);
    });
  });
}
