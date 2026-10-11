import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wifi_desk/features/productivity/data/datasources/clipboard_datasource.dart';
import 'package:wifi_desk/features/productivity/data/repositories/clipboard_repository_impl.dart';

class MockClipboardDatasource extends Mock implements ClipboardDatasource {}

void main() {
  late MockClipboardDatasource mockDatasource;
  late ClipboardRepositoryImpl repository;

  const testSerial = '192.168.1.100:5555';

  setUp(() {
    mockDatasource = MockClipboardDatasource();
    repository = ClipboardRepositoryImpl(datasource: mockDatasource);
  });

  group('ClipboardRepositoryImpl', () {
    test('syncHostToDevice copies text from host to device', () async {
      when(() => mockDatasource.readHostClipboard())
          .thenAnswer((_) async => 'Hello from Mac');
      when(
        () => mockDatasource.writeDeviceClipboard(testSerial, 'Hello from Mac'),
      ).thenAnswer((_) async => true);

      final result = await repository.syncHostToDevice(testSerial);

      expect(result, isTrue);
      verify(() => mockDatasource.readHostClipboard()).called(1);
      verify(
        () => mockDatasource.writeDeviceClipboard(testSerial, 'Hello from Mac'),
      ).called(1);
    });

    test('syncHostToDevice returns false if host clipboard is empty', () async {
      when(() => mockDatasource.readHostClipboard())
          .thenAnswer((_) async => '');

      final result = await repository.syncHostToDevice(testSerial);

      expect(result, isFalse);
      verifyNever(() => mockDatasource.writeDeviceClipboard(any(), any()));
    });

    test('syncDeviceToHost copies text from device to host', () async {
      when(() => mockDatasource.readDeviceClipboard(testSerial))
          .thenAnswer((_) async => 'Hello from Android');
      when(() => mockDatasource.writeHostClipboard('Hello from Android'))
          .thenAnswer((_) async {});

      final result = await repository.syncDeviceToHost(testSerial);

      expect(result, isTrue);
      verify(() => mockDatasource.readDeviceClipboard(testSerial)).called(1);
      verify(() => mockDatasource.writeHostClipboard('Hello from Android'))
          .called(1);
    });
  });
}
