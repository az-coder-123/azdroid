import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wifi_desk/features/productivity/domain/entities/file_transfer_entity.dart';
import 'package:wifi_desk/features/productivity/domain/repositories/file_transfer_repository.dart';
import 'package:wifi_desk/features/productivity/presentation/cubit/file_transfer_cubit.dart';
import 'package:wifi_desk/features/productivity/presentation/cubit/file_transfer_state.dart';

class MockFileTransferRepository extends Mock
    implements FileTransferRepository {}

void main() {
  late MockFileTransferRepository mockRepository;
  const testSerial = '192.168.1.100:5555';

  setUp(() {
    mockRepository = MockFileTransferRepository();
  });

  group('FileTransferCubit', () {
    test('initial state is FileTransferInitial', () {
      final cubit = FileTransferCubit(repository: mockRepository);
      expect(cubit.state, isA<FileTransferInitial>());
      cubit.close();
    });

    blocTest<FileTransferCubit, FileTransferState>(
      'transferFiles pushes standard file and emits [FileTransferActive, FileTransferSuccess]',
      build: () {
        when(() => mockRepository.pushFile(testSerial, '/Users/mac/photo.png'))
            .thenAnswer((_) async => true);
        return FileTransferCubit(repository: mockRepository);
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
        return FileTransferCubit(repository: mockRepository);
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
        return FileTransferCubit(repository: mockRepository);
      },
      act: (cubit) =>
          cubit.transferFiles(testSerial, ['/Users/mac/failed.doc']),
      expect: () => [isA<FileTransferActive>(), isA<FileTransferFailure>()],
    );
  });
}
