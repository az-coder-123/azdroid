import 'package:desk_droid/core/platform/file_picker/host_file_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FileSelectorHostFilePicker', () {
    test('pickFiles returns every selected path', () async {
      final picker = FileSelectorHostFilePicker(
        openFiles: ({
          acceptedTypeGroups = const [],
          confirmButtonText,
          initialDirectory,
        }) async => [XFile('/a.txt'), XFile(r'C:\b.png')],
      );

      expect(await picker.pickFiles(), ['/a.txt', r'C:\b.png']);
    });

    test('pickFiles returns an empty list on cancel', () async {
      final picker = FileSelectorHostFilePicker(
        openFiles: ({
          acceptedTypeGroups = const [],
          confirmButtonText,
          initialDirectory,
        }) async => [],
      );

      expect(await picker.pickFiles(), isEmpty);
    });

    test('pickApkFile filters by the apk extension', () async {
      List<XTypeGroup>? groups;
      final picker = FileSelectorHostFilePicker(
        openFile:
            ({
              acceptedTypeGroups = const [],
              confirmButtonText,
              initialDirectory,
            }) async {
              groups = acceptedTypeGroups;
              return XFile('/apps/app.apk');
            },
      );

      expect(await picker.pickApkFile(), '/apps/app.apk');
      expect(groups!.single.extensions, ['apk']);
    });

    test('pickApkFile returns null on cancel', () async {
      final picker = FileSelectorHostFilePicker(
        openFile: ({
          acceptedTypeGroups = const [],
          confirmButtonText,
          initialDirectory,
        }) async => null,
      );

      expect(await picker.pickApkFile(), isNull);
    });
  });
}
