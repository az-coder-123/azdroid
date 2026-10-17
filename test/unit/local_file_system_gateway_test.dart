import 'dart:io';

import 'package:desk_droid/core/services/local_file_system_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  const gateway = IoLocalFileSystemGateway();

  setUp(() => root = Directory.systemTemp.createTempSync('fs_gateway_'));
  tearDown(() => root.deleteSync(recursive: true));

  group('IoLocalFileSystemGateway', () {
    test('keeps files and expands directories recursively', () {
      // Use host separators: directory listings return them on every OS.
      final single = File(p.join(root.path, 'single.txt'))
        ..writeAsStringSync('a');
      final nested = File(p.join(root.path, 'dir', 'sub', 'nested.txt'))
        ..createSync(recursive: true);

      final result = gateway.expandToFiles([
        single.path,
        p.join(root.path, 'dir'),
      ]);

      expect(result, [single.path, nested.path]);
    });

    test('skips empty and missing paths', () {
      expect(gateway.expandToFiles(['', '${root.path}/missing']), isEmpty);
    });

    test('fileSizeOf returns byte length, or zero when missing', () {
      final file = File('${root.path}/data.bin')..writeAsBytesSync([1, 2, 3]);

      expect(gateway.fileSizeOf(file.path), 3);
      expect(gateway.fileSizeOf('${root.path}/missing'), 0);
    });
  });
}
