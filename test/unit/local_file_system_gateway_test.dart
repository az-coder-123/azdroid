import 'dart:io';

import 'package:desk_droid/core/services/local_file_system_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory root;
  const gateway = IoLocalFileSystemGateway();

  setUp(() => root = Directory.systemTemp.createTempSync('fs_gateway_'));
  tearDown(() => root.deleteSync(recursive: true));

  group('IoLocalFileSystemGateway', () {
    test('keeps files and expands directories recursively', () {
      final single = File('${root.path}/single.txt')..writeAsStringSync('a');
      final nested = File('${root.path}/dir/sub/nested.txt')
        ..createSync(recursive: true);

      final result = gateway.expandToFiles([single.path, '${root.path}/dir']);

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
