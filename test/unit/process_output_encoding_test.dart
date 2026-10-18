import 'dart:convert';
import 'dart:io';

import 'package:desk_droid/core/services/process_output_encoding.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('processOutputEncodingFor', () {
    test('uses UTF-8 for adb on every path style', () {
      for (final adb in [
        'adb',
        'adb.exe',
        'ADB.EXE',
        r'C:\Users\me\AppData\Local\Android\Sdk\platform-tools\adb.exe',
        '/opt/homebrew/bin/adb',
      ]) {
        expect(processOutputEncodingFor(adb), adbOutputEncoding, reason: adb);
      }
    });

    test('keeps the system encoding for host tools', () {
      for (final tool in ['where', 'arp', 'powershell.exe', '/usr/bin/which']) {
        expect(processOutputEncodingFor(tool), systemEncoding, reason: tool);
      }
      // A file that merely contains "adb" is not adb.
      expect(processOutputEncodingFor('adbkey'), systemEncoding);
    });
  });

  group('adbOutputEncoding', () {
    test('decodes Vietnamese UI text from the device intact', () {
      final bytes = utf8.encode('text="Cài đặt" desc="Quản lý Tập tin"');

      expect(
        adbOutputEncoding.decode(bytes),
        'text="Cài đặt" desc="Quản lý Tập tin"',
      );
    });

    test('replaces malformed bytes instead of throwing', () {
      expect(adbOutputEncoding.decode([0x41, 0xFF, 0x42]), 'A\uFFFDB');
    });
  });
}
