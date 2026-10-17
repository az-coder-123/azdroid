import 'package:bloc_test/bloc_test.dart';
import 'package:desk_droid/core/platform/file_picker/host_file_picker.dart';
import 'package:desk_droid/features/productivity/domain/entities/file_transfer_entity.dart';
import 'package:desk_droid/features/productivity/domain/repositories/file_transfer_repository.dart';
import 'package:desk_droid/features/productivity/presentation/cubit/file_transfer_cubit.dart';
import 'package:desk_droid/features/productivity/presentation/cubit/file_transfer_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/fake_local_file_system_gateway.dart';

class MockFileTransferRepository extends Mock
    implements FileTransferRepository {}

class MockHostFilePicker extends Mock implements HostFilePicker {}

void main() {
  late MockFileTransferRepository mockRepository;
  const testSerial = '192.168.1.100:5555';

  setUp(() {
    mockRepository = MockFileTransferRepository();
  });

  group('FileTransferCubit', () {
    test('initial state is FileTransferInitial', () {
      final cubit = FileTransferCubit(
        repository: mockRepository,
        fileSystem: const FakeLocalFileSystemGateway(),
      );
      expect(cubit.state, isA<FileTransferInitial>());
      cubit.close();
    });

    blocTest<FileTransferCubit, FileTransferState>(
      'transferFiles pushes standard file and emits [FileTransferActive, FileTransferSuccess]',
      build: () {
        when(() => mockRepository.pushFile(testSerial, '/Users/mac/photo.png'))
            .thenAnswer((_) async => true);
        return FileTransferCubit(
          repository: mockRepository,
          fileSystem: const FakeLocalFileSystemGateway(),
        );
      },
      act: (cubit) => cubit.transferFiles(testSerial, ['/Users/mac/photo.png']),
      expect: () => [
        isA<FileTransferActive>().having(
          (s) => s.currentTransfer.fileName,
          'fileName',
          'photo.png',
        ),
        isA<FileTransferSuccess>().having(
          (s) => s.completedTransfer.status,
          'status',
          FileTransferStatus.completed,
        ),
      ],
    );

    blocTest<FileTransferCubit, FileTransferState>(
      'transferFiles recognizes .apk and delegates to installApk',
      build: () {
        when(() => mockRepository.installApk(testSerial, '/Users/mac/app.apk'))
            .thenAnswer((_) async => true);
        return FileTransferCubit(
          repository: mockRepository,
          fileSystem: const FakeLocalFileSystemGateway(),
        );
      },
      act: (cubit) => cubit.transferFiles(testSerial, ['/Users/mac/app.apk']),
      expect: () => [
        isA<FileTransferActive>().having(
          (s) => s.currentTransfer.isApk,
          'isApk',
          isTrue,
        ),
        isA<FileTransferSuccess>().having(
          (s) => s.completedTransfer.isApk,
          'isApk',
          isTrue,
        ),
      ],
    );

    blocTest<FileTransferCubit, FileTransferState>(
      'transferFiles emits FileTransferFailure when push fails',
      build: () {
        when(() => mockRepository.pushFile(testSerial, '/Users/mac/failed.doc'))
            .thenAnswer((_) async => false);
        return FileTransferCubit(
          repository: mockRepository,
          fileSystem: const FakeLocalFileSystemGateway(),
        );
      },
      act: (cubit) =>
          cubit.transferFiles(testSerial, ['/Users/mac/failed.doc']),
      expect: () => [isA<FileTransferActive>(), isA<FileTransferFailure>()],
    );

    test('autoResetDuration automatically resets state to initial after completion', () async {
      when(() => mockRepository.pushFile(testSerial, '/Users/mac/test.png'))
          .thenAnswer((_) async => true);

      final cubit = FileTransferCubit(
        repository: mockRepository,
        fileSystem: const FakeLocalFileSystemGateway(),
        autoResetDuration: const Duration(milliseconds: 30),
      );

      await cubit.transferFiles(testSerial, ['/Users/mac/test.png']);
      expect(cubit.state, isA<FileTransferSuccess>());

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(cubit.state, isA<FileTransferInitial>());

      await cubit.close();
    });

    blocTest<FileTransferCubit, FileTransferState>(
      'transferFiles expands dropped directories into their contained files',
      build: () {
        when(() => mockRepository.pushFile(testSerial, any()))
            .thenAnswer((_) async => true);
        return FileTransferCubit(
          repository: mockRepository,
          fileSystem: const FakeLocalFileSystemGateway(
            directories: {
              '/Users/mac/album': [
                '/Users/mac/album/a.jpg',
                '/Users/mac/album/b.jpg',
              ],
            },
          ),
          autoResetDuration: null,
        );
      },
      act: (cubit) => cubit.transferFiles(testSerial, ['/Users/mac/album']),
      verify: (_) {
        verify(
          () => mockRepository.pushFile(testSerial, '/Users/mac/album/a.jpg'),
        ).called(1);
        verify(
          () => mockRepository.pushFile(testSerial, '/Users/mac/album/b.jpg'),
        ).called(1);
      },
    );

    blocTest<FileTransferCubit, FileTransferState>(
      'transferFiles emits nothing when no files remain after expansion',
      build: () => FileTransferCubit(
        repository: mockRepository,
        fileSystem: const FakeLocalFileSystemGateway(
          directories: {'/Users/mac/empty': []},
        ),
      ),
      act: (cubit) => cubit.transferFiles(testSerial, ['/Users/mac/empty']),
      expect: () => <FileTransferState>[],
    );

    test(
      'reset() immediately emits FileTransferInitial and cancels timer',
      () async {
        when(() => mockRepository.pushFile(testSerial, '/Users/mac/test.png'))
            .thenAnswer((_) async => true);

        final cubit = FileTransferCubit(
          repository: mockRepository,
          fileSystem: const FakeLocalFileSystemGateway(),
          autoResetDuration: const Duration(seconds: 10),
        );

        await cubit.transferFiles(testSerial, ['/Users/mac/test.png']);
        expect(cubit.state, isA<FileTransferSuccess>());

        cubit.reset();
        expect(cubit.state, isA<FileTransferInitial>());

        await cubit.close();
      },
    );
  });

  group('FileTransferCubit.pickAndTransferFiles', () {
    late MockHostFilePicker picker;

    setUp(() => picker = MockHostFilePicker());

    FileTransferCubit build() => FileTransferCubit(
      repository: mockRepository,
      fileSystem: const FakeLocalFileSystemGateway(),
      filePicker: picker,
      autoResetDuration: null,
    );

    test('transfers every picked file', () async {
      when(() => picker.pickFiles())
          .thenAnswer((_) async => ['/Users/mac/a.txt']);
      when(() => mockRepository.pushFile(testSerial, '/Users/mac/a.txt'))
          .thenAnswer((_) async => true);

      final cubit = build();
      await cubit.pickAndTransferFiles(testSerial);

      verify(() => mockRepository.pushFile(testSerial, '/Users/mac/a.txt'))
          .called(1);
      await cubit.close();
    });

    test('does nothing when the picker is cancelled', () async {
      when(() => picker.pickFiles()).thenAnswer((_) async => []);

      final cubit = build();
      await cubit.pickAndTransferFiles(testSerial);

      expect(cubit.state, isA<FileTransferInitial>());
      verifyNever(() => mockRepository.pushFile(any(), any()));
      await cubit.close();
    });
  });
}
