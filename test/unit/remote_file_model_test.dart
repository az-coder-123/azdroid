import 'package:flutter_test/flutter_test.dart';
import 'package:wifi_desk/features/productivity/data/models/remote_file_model.dart';

void main() {
  group('RemoteFileModel', () {
    test('correctly parses directory line from adb shell ls -lp', () {
      const line =
          'drwxrwx--x 2 root sdcard_rw 4096 2026-09-13 22:40 NearSend/';
      final model = RemoteFileModel.fromLsLine(line, '/sdcard/Download');

      expect(model, isNotNull);
      expect(model!.name, equals('NearSend'));
      expect(model.path, equals('/sdcard/Download/NearSend'));
      expect(model.isDirectory, isTrue);
      expect(model.formattedSize, equals('--'));
    });

    test('correctly parses video file line and computes properties', () {
      const line =
          '-rw-rw---- 1 root sdcard_rw 38941140 2026-08-15 01:01 video_360p-1.mp4';
      final model = RemoteFileModel.fromLsLine(line, '/sdcard/Download');

      expect(model, isNotNull);
      expect(model!.name, equals('video_360p-1.mp4'));
      expect(model.path, equals('/sdcard/Download/video_360p-1.mp4'));
      expect(model.isDirectory, isFalse);
      expect(model.sizeBytes, equals(38941140));
      expect(model.formattedSize, equals('37.1 MB'));
      expect(model.isVideo, isTrue);
      expect(model.isImage, isFalse);
    });

    test('correctly identifies image and APK files', () {
      const imgLine =
          '-rw-rw---- 1 root sdcard_rw 1048576 2026-10-01 10:00 photo.JPG';
      final imgModel = RemoteFileModel.fromLsLine(imgLine, '/sdcard/DCIM');
      expect(imgModel!.isImage, isTrue);
      expect(imgModel.formattedSize, equals('1.0 MB'));

      const apkLine =
          '-rw-rw---- 1 root sdcard_rw 52428800 2026-10-02 12:00 app.apk';
      final apkModel = RemoteFileModel.fromLsLine(apkLine, '/sdcard/Download');
      expect(apkModel!.isApk, isTrue);
    });

    test('returns null for total line and dot directories', () {
      expect(RemoteFileModel.fromLsLine('total 422536', '/sdcard'), isNull);
      expect(
        RemoteFileModel.fromLsLine(
          'drwxrwx--x 2 root sdcard_rw 4096 2026-09-13 22:40 .',
          '/sdcard',
        ),
        isNull,
      );
      expect(
        RemoteFileModel.fromLsLine(
          'drwxrwx--x 2 root sdcard_rw 4096 2026-09-13 22:40 ..',
          '/sdcard',
        ),
        isNull,
      );
    });
  });
}
