import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wifi_desk/features/productivity/data/datasources/file_transfer_datasource.dart';
import 'package:wifi_desk/features/productivity/data/repositories/file_transfer_repository_impl.dart';

class MockFileTransferDatasource extends Mock
    implements FileTransferDatasource {}

void main() {
  late MockFileTransferDatasource mockDatasource;
  late FileTransferRepositoryImpl repository;

  const testSerial = '192.168.1.100:5555';

  setUp(() {
    mockDatasource = MockFileTransferDatasource();
    repository = FileTransferRepositoryImpl(datasource: mockDatasource);
  });

  group('FileTransferRepositoryImpl', () {
    test(
      'pushFile delegates to datasource with default download dir',
      () async {
        when(
          () => mockDatasource.pushFile(
            testSerial,
            '/tmp/test.png',
            '/sdcard/Download/',
          ),
        ).thenAnswer((_) async => true);

        final result = await repository.pushFile(testSerial, '/tmp/test.png');

        expect(result, isTrue);
        verify(
          () => mockDatasource.pushFile(
            testSerial,
            '/tmp/test.png',
            '/sdcard/Download/',
          ),
        ).called(1);
      },
    );

    test('installApk delegates to datasource', () async {
      when(() => mockDatasource.installApk(testSerial, '/tmp/app.apk'))
          .thenAnswer((_) async => true);

      final result = await repository.installApk(testSerial, '/tmp/app.apk');

      expect(result, isTrue);
      verify(() => mockDatasource.installApk(testSerial, '/tmp/app.apk'))
          .called(1);
    });

    test('pullFile delegates to datasource', () async {
      when(
        () => mockDatasource.pullFile(
          testSerial,
          '/sdcard/Download/test.mp4',
          '/local/Downloads',
        ),
      ).thenAnswer((_) async => true);

      final result = await repository.pullFile(
        testSerial,
        '/sdcard/Download/test.mp4',
        '/local/Downloads',
      );

      expect(result, isTrue);
      verify(
        () => mockDatasource.pullFile(
          testSerial,
          '/sdcard/Download/test.mp4',
          '/local/Downloads',
        ),
      ).called(1);
    });

    test('listRemoteFiles delegates to datasource', () async {
      when(
        () => mockDatasource.listRemoteFiles(testSerial, '/sdcard/Download/'),
      ).thenAnswer((_) async => []);

      final result = await repository.listRemoteFiles(
        testSerial,
        '/sdcard/Download/',
      );

      expect(result, isEmpty);
      verify(
        () => mockDatasource.listRemoteFiles(testSerial, '/sdcard/Download/'),
      ).called(1);
    });

    test('getExternalStorageDirectory delegates to datasource', () async {
      when(() => mockDatasource.getExternalStorageDirectory(testSerial))
          .thenAnswer((_) async => '/storage/3662-FF26/');

      final result = await repository.getExternalStorageDirectory(testSerial);

      expect(result, equals('/storage/3662-FF26/'));
      verify(() => mockDatasource.getExternalStorageDirectory(testSerial))
          .called(1);
    });
  });
}
