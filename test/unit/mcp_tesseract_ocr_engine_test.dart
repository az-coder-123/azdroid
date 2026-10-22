import 'dart:io';

import 'package:desk_droid/core/platform/host_os.dart';
import 'package:desk_droid/core/platform/host_paths.dart';
import 'package:desk_droid/core/services/process_executor.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_tesseract_ocr_engine.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_tesseract_parser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/test_toolchains.dart';

class MockProcessExecutor extends Mock implements ProcessExecutor {}

void main() {
  late MockProcessExecutor mockExecutor;
  late HostPaths fakePaths;
  late McpTesseractOcrEngine engine;

  setUp(() {
    mockExecutor = MockProcessExecutor();
    fakePaths = SystemHostPaths(
      os: HostOs.macos,
      environment: const {},
      systemTempPath: Directory.systemTemp.path,
    );
    engine = McpTesseractOcrEngine(
      toolchain: toolchainFor(HostOs.macos, const {}),
      paths: fakePaths,
      executor: mockExecutor,
      parser: const McpTesseractParser(),
      fileExists: (path) async => path == '/usr/local/bin/tesseract',
    );
  });

  group('McpTesseractOcrEngine Tests', () {
    test(
      'isAvailable returns true when tesseract executable is discovered',
      () async {
        when(() => mockExecutor.run('/usr/bin/which', ['tesseract']))
            .thenAnswer(
              (_) async =>
                  ProcessResult(1, 0, '/usr/local/bin/tesseract\n', ''),
            );

        final available = await engine.isAvailable();
        expect(available, isTrue);
      },
    );

    test('isAvailable returns false when executable is not found', () async {
      final unconfiguredEngine = McpTesseractOcrEngine(
        toolchain: toolchainFor(HostOs.macos, const {}),
        paths: fakePaths,
        executor: mockExecutor,
        parser: const McpTesseractParser(),
        fileExists: (_) async => false,
      );

      when(() => mockExecutor.run('/usr/bin/which', ['tesseract']))
          .thenAnswer((_) async => ProcessResult(1, 1, '', 'not found'));
      when(
        () => mockExecutor.run('tesseract', ['--version']),
      ).thenAnswer((_) async => ProcessResult(1, 127, '', 'command not found'));

      final available = await unconfiguredEngine.isAvailable();
      expect(available, isFalse);
    });

    test('recognize returns empty list when image bytes are empty', () async {
      final elements = await engine.recognize(const []);
      expect(elements, isEmpty);
      verifyZeroInteractions(mockExecutor);
    });

    test('recognize runs tesseract tsv and parses output on success', () async {
      when(() => mockExecutor.run('/usr/bin/which', ['tesseract'])).thenAnswer(
        (_) async => ProcessResult(1, 0, '/usr/local/bin/tesseract\n', ''),
      );

      const fakeTsv = '''
level\tpage_num\tblock_num\tpar_num\tline_num\tword_num\tleft\ttop\twidth\theight\tconf\ttext
5\t1\t1\t1\t1\t1\t120\t340\t60\t25\t95.0\tConfirm
''';

      when(
        () => mockExecutor.run(
          '/usr/local/bin/tesseract',
          any(),
          timeout: any(named: 'timeout'),
        ),
      ).thenAnswer((_) async => ProcessResult(2, 0, fakeTsv, ''));

      final elements = await engine.recognize([1, 2, 3, 4]);
      expect(elements.length, equals(1));
      expect(elements.first.text, equals('Confirm'));
      expect(elements.first.centerX, equals(150));
      expect(elements.first.centerY, equals(352));
    });

    test(
      'recognize returns empty list on process failure or timeout',
      () async {
        when(() => mockExecutor.run('/usr/bin/which', ['tesseract']))
            .thenAnswer(
              (_) async =>
                  ProcessResult(1, 0, '/usr/local/bin/tesseract\n', ''),
            );

        when(
          () => mockExecutor.run(
            '/usr/local/bin/tesseract',
            any(),
            timeout: any(named: 'timeout'),
          ),
        ).thenAnswer((_) async => ProcessResult(2, 1, '', 'OCR error'));

        final elements = await engine.recognize([1, 2, 3, 4]);
        expect(elements, isEmpty);
      },
    );
  });
}
