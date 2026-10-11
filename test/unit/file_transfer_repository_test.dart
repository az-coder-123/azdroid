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
  });
}
