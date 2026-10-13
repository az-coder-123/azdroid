import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wifi_desk/core/services/process_executor.dart';
import 'package:wifi_desk/features/productivity/domain/entities/remote_file_entity.dart';
import 'package:wifi_desk/features/productivity/domain/repositories/file_transfer_repository.dart';
import 'package:wifi_desk/features/productivity/presentation/cubit/device_file_manager_cubit.dart';
import 'package:wifi_desk/features/productivity/presentation/cubit/device_file_manager_state.dart';

class MockFileTransferRepository extends Mock
    implements FileTransferRepository {}

class MockProcessExecutor extends Mock implements ProcessExecutor {}

void main() {
  late MockFileTransferRepository mockRepository;
  late MockProcessExecutor mockExecutor;
  late DeviceFileManagerCubit cubit;

  const testSerial = '192.168.1.3:5555';
  const testDirectory = '/sdcard/Download/';

  const sampleFile1 = RemoteFileEntity(
    name: 'photo.jpg',
    path: '/sdcard/Download/photo.jpg',
    sizeBytes: 2048,
    isDirectory: false,
  );

  const sampleDir = RemoteFileEntity(
    name: 'Music',
    path: '/sdcard/Download/Music',
    sizeBytes: 0,
    isDirectory: true,
  );

  setUp(() {
    mockRepository = MockFileTransferRepository();
    mockExecutor = MockProcessExecutor();
    cubit = DeviceFileManagerCubit(
      repository: mockRepository,
      processExecutor: mockExecutor,
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('DeviceFileManagerCubit', () {
    test('initial state is DeviceFileManagerInitial', () {
      expect(cubit.state, equals(const DeviceFileManagerInitial()));
    });

    blocTest<DeviceFileManagerCubit, DeviceFileManagerState>(
      'loadDirectory emits [Loading, Loaded] sorting directories first',
      build: () {
        when(() => mockRepository.listRemoteFiles(testSerial, testDirectory))
            .thenAnswer((_) async => [sampleFile1, sampleDir]);
        return cubit;
      },
      act: (c) => c.loadDirectory(testSerial, directory: testDirectory),
      expect: () => [
        const DeviceFileManagerLoading(currentDirectory: testDirectory),
        const DeviceFileManagerLoaded(
          currentDirectory: testDirectory,
          files: [sampleDir, sampleFile1],
          selectedFiles: {},
        ),
      ],
    );

    blocTest<DeviceFileManagerCubit, DeviceFileManagerState>(
      'toggleFileSelection adds and removes paths from selectedFiles',
      build: () => cubit,
      seed: () => const DeviceFileManagerLoaded(
        currentDirectory: testDirectory,
        files: [sampleFile1],
        selectedFiles: {},
      ),
      act: (c) {
        c.toggleFileSelection(sampleFile1.path);
        c.toggleFileSelection(sampleFile1.path);
      },
      expect: () => [
        const DeviceFileManagerLoaded(
          currentDirectory: testDirectory,
          files: [sampleFile1],
          selectedFiles: {'/sdcard/Download/photo.jpg'},
        ),
        const DeviceFileManagerLoaded(
          currentDirectory: testDirectory,
          files: [sampleFile1],
          selectedFiles: {},
        ),
      ],
    );

    blocTest<DeviceFileManagerCubit, DeviceFileManagerState>(
      'downloadSelected pulls each selected file and emits success message',
      build: () {
        when(() => mockRepository.pullFile(testSerial, sampleFile1.path, any()))
            .thenAnswer((_) async => true);
        return cubit;
      },
      seed: () => const DeviceFileManagerLoaded(
        currentDirectory: testDirectory,
        files: [sampleFile1],
        selectedFiles: {'/sdcard/Download/photo.jpg'},
      ),
      act: (c) =>
          c.downloadSelected(testSerial, destinationDirectory: '/tmp/test_dl'),
      expect: () => [
        const DeviceFileManagerLoaded(
          currentDirectory: testDirectory,
          files: [sampleFile1],
          selectedFiles: {'/sdcard/Download/photo.jpg'},
          isDownloading: true,
        ),
        predicate<DeviceFileManagerLoaded>(
          (s) =>
              !s.isDownloading &&
              s.selectedFiles.isEmpty &&
              s.statusMessage != null &&
              s.statusMessage!.contains('Downloaded 1/1 file(s)'),
        ),
      ],
    );
  });
}
