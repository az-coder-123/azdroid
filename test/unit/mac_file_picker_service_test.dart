import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wifi_desk/core/services/mac_file_picker_service.dart';
import 'package:wifi_desk/core/services/process_executor.dart';

class MockProcessExecutor extends Mock implements ProcessExecutor {}

void main() {
  late MockProcessExecutor mockExecutor;
  late MacFilePickerServiceImpl service;

  setUp(() {
    mockExecutor = MockProcessExecutor();
    service = MacFilePickerServiceImpl(processExecutor: mockExecutor);
  });

  group('MacFilePickerServiceImpl', () {
    test('pickFiles parses multiple returned POSIX paths', () async {
      const output =
          '/Users/test/Documents/report.pdf\n/Users/test/Images/pic.png';

      when(() => mockExecutor.run('osascript', any()))
          .thenAnswer((_) async => ProcessResult(0, 0, output, ''));

      final files = await service.pickFiles();

      expect(files.length, equals(2));
      expect(files[0], equals('/Users/test/Documents/report.pdf'));
      expect(files[1], equals('/Users/test/Images/pic.png'));
    });

    test(
      'pickFiles returns empty list on user cancel or empty output',
      () async {
        when(() => mockExecutor.run('osascript', any()))
            .thenAnswer((_) async => ProcessResult(0, 0, '', ''));

        final files = await service.pickFiles();
        expect(files, isEmpty);
      },
    );

    test('pickDirectory returns selected folder path', () async {
      const folder = '/Users/test/Downloads';
      when(() => mockExecutor.run('osascript', any()))
          .thenAnswer((_) async => ProcessResult(0, 0, folder, ''));

      final result = await service.pickDirectory();
      expect(result, equals(folder));
    });
  });
}
