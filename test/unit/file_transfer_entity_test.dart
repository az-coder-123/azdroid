import 'package:flutter_test/flutter_test.dart';
import 'package:desk_droid/features/productivity/domain/entities/file_transfer_entity.dart';

void main() {
  group('FileTransferEntity', () {
    test('formattedSize returns empty string when fileSizeBytes <= 0', () {
      const entity = FileTransferEntity(
        id: '1',
        fileName: 'test.txt',
        localPath: '/tmp/test.txt',
        fileSizeBytes: 0,
      );
      expect(entity.formattedSize, isEmpty);
    });

    test('formattedSize formats bytes, KB, MB, and GB properly', () {
      const bytesEntity = FileTransferEntity(
        id: '1',
        fileName: 'small.txt',
        localPath: '/tmp/small.txt',
        fileSizeBytes: 512,
      );
      expect(bytesEntity.formattedSize, equals('512 B'));

      const kbEntity = FileTransferEntity(
        id: '2',
        fileName: 'doc.pdf',
        localPath: '/tmp/doc.pdf',
        fileSizeBytes: 1024 * 50,
      );
      expect(kbEntity.formattedSize, equals('50.0 KB'));

      final mbEntity = FileTransferEntity(
        id: '3',
        fileName: 'video.mp4',
        localPath: '/tmp/video.mp4',
        fileSizeBytes: (1024 * 1024 * 15.5).toInt(),
      );
      expect(mbEntity.formattedSize, equals('15.5 MB'));

      final gbEntity = FileTransferEntity(
        id: '4',
        fileName: 'large.zip',
        localPath: '/tmp/large.zip',
        fileSizeBytes: (1024 * 1024 * 1024 * 2.5).toInt(),
      );
      expect(gbEntity.formattedSize, equals('2.50 GB'));
    });

    test('copyWith updates properties properly', () {
      const entity = FileTransferEntity(
        id: '1',
        fileName: 'initial.apk',
        localPath: '/tmp/initial.apk',
        fileSizeBytes: 1024,
        isApk: true,
        status: FileTransferStatus.inProgress,
      );

      final updated = entity.copyWith(
        status: FileTransferStatus.completed,
        fileSizeBytes: 2048,
      );

      expect(updated.status, equals(FileTransferStatus.completed));
      expect(updated.fileSizeBytes, equals(2048));
      expect(updated.fileName, equals('initial.apk'));
    });
  });
}
