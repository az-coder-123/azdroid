import 'dart:io';

import 'package:desk_droid/features/mcp/data/services/mcp_adb_client.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_ocr_fallback_ops.dart';
import 'package:desk_droid/features/mcp/domain/entities/mcp_ocr_element.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_ocr_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockMcpAdbClient extends Mock implements McpAdbClient {}

class MockMcpOcrEngine extends Mock implements McpOcrEngine {}

void main() {
  late MockMcpAdbClient mockAdb;
  late MockMcpOcrEngine mockEngine;

  setUp(() {
    mockAdb = MockMcpAdbClient();
    mockEngine = MockMcpOcrEngine();
    McpOcrFallbackOps.setDefaultEngineForTesting(mockEngine);
  });

  tearDown(() {
    McpOcrFallbackOps.setDefaultEngineForTesting(null);
  });

  group('McpAdbUiOps Multi-Stage OCR Fallback Tests', () {
    test(
      'Stage 1 succeeds: ignores uncompressed dump and OCR completely',
      () async {
        const compressedXml = '''
<hierarchy>
  <node text="Home" bounds="[10,20][100,50]" clickable="true"/>
</hierarchy>
''';
        when(() => mockAdb.run(any()))
            .thenAnswer((_) async => ProcessResult(1, 0, compressedXml, ''));
        when(() => mockAdb.getDisplaySize('device_1'))
            .thenAnswer((_) async => const Point(1080, 1920));

        final result = await McpAdbUiOps.findElement(
          mockAdb,
          'device_1',
          text: 'Home',
        );

        expect(result, isNotNull);
        expect(result!['text'], equals('Home'));
        expect(result['source'], isNull); // Native semantic tree node
        // dumpHierarchy executes 2 calls: uiautomator dump + cat tmpXml
        verify(() => mockAdb.run(any())).called(2);
        verifyZeroInteractions(mockEngine);
      },
    );

    test(
      'Stage 2 succeeds: resolves Compose element without triggering OCR',
      () async {
        const compressedXml = '<hierarchy></hierarchy>';
        const uncompressedXml = '''
<hierarchy>
  <node text="Compose Tab" bounds="[50,50][200,100]" clickable="true"/>
</hierarchy>
''';
        var isCompressedAttempt = true;
        when(() => mockAdb.run(any())).thenAnswer((inv) async {
          final args = inv.positionalArguments.first as List<String>;
          if (args.contains('--compressed')) {
            isCompressedAttempt = true;
            return ProcessResult(1, 0, '', '');
          }
          if (args.contains('cat')) {
            final xml = isCompressedAttempt ? compressedXml : uncompressedXml;
            return ProcessResult(1, 0, xml, '');
          }
          isCompressedAttempt = false;
          return ProcessResult(1, 0, '', '');
        });
        when(() => mockAdb.getDisplaySize('device_1'))
            .thenAnswer((_) async => const Point(1080, 1920));

        final result = await McpAdbUiOps.findElement(
          mockAdb,
          'device_1',
          text: 'Compose Tab',
        );

        expect(result, isNotNull);
        expect(result!['text'], equals('Compose Tab'));
        // 2 calls for compressed + 2 calls for uncompressed = 4 calls
        verify(() => mockAdb.run(any())).called(4);
        verifyZeroInteractions(mockEngine);
      },
    );

    test(
      'Stage 3 fallback: discovers zero-accessibility canvas text via OCR',
      () async {
        const emptyXml = '<hierarchy></hierarchy>';
        when(() => mockAdb.run(any()))
            .thenAnswer((_) async => ProcessResult(1, 0, emptyXml, ''));
        when(() => mockAdb.getDisplaySize('device_1'))
            .thenAnswer((_) async => const Point(1080, 1920));

        when(() => mockEngine.isAvailable()).thenAnswer((_) async => true);
        when(() => mockAdb.captureScreenshotBytes('device_1'))
            .thenAnswer((_) async => [1, 2, 3, 4]);
        when(() => mockEngine.recognize([1, 2, 3, 4])).thenAnswer(
          (_) async => const [
            McpOcrElement(
              text: 'Start Adventure',
              left: 300,
              top: 800,
              width: 480,
              height: 120,
              confidence: 0.97,
            ),
          ],
        );

        final result = await McpAdbUiOps.findElement(
          mockAdb,
          'device_1',
          text: 'Start Adventure',
        );

        expect(result, isNotNull);
        expect(result!['text'], equals('Start Adventure'));
        expect(result['source'], equals('ocr_stage_3'));
        expect(result['centerPixels'], equals({'x': 540, 'y': 860}));
        expect(result['confidence'], equals(0.97));
      },
    );

    test(
      'clickElement taps center of element discovered via OCR Stage 3',
      () async {
        const emptyXml = '<hierarchy></hierarchy>';
        when(() => mockAdb.run(any()))
            .thenAnswer((_) async => ProcessResult(1, 0, emptyXml, ''));
        when(() => mockAdb.getDisplaySize('device_1'))
            .thenAnswer((_) async => const Point(1080, 1920));

        when(() => mockEngine.isAvailable()).thenAnswer((_) async => true);
        when(() => mockAdb.captureScreenshotBytes('device_1'))
            .thenAnswer((_) async => [1, 2, 3, 4]);
        when(() => mockEngine.recognize([1, 2, 3, 4])).thenAnswer(
          (_) async => const [
            McpOcrElement(
              text: 'Play Game',
              left: 200,
              top: 400,
              width: 200,
              height: 100,
              confidence: 0.99,
            ),
          ],
        );
        when(() => mockAdb.tap('device_1', 300.0, 450.0))
            .thenAnswer((_) async => true);

        final success = await McpAdbUiOps.clickElement(
          mockAdb,
          'device_1',
          text: 'Play Game',
        );

        expect(success, isTrue);
        verify(() => mockAdb.tap('device_1', 300.0, 450.0)).called(1);
      },
    );

    test(
      'does not invoke OCR if query only specifies resourceId without text',
      () async {
        const emptyXml = '<hierarchy></hierarchy>';
        when(() => mockAdb.run(any()))
            .thenAnswer((_) async => ProcessResult(1, 0, emptyXml, ''));
        when(() => mockAdb.getDisplaySize('device_1'))
            .thenAnswer((_) async => const Point(1080, 1920));

        final result = await McpAdbUiOps.findElement(
          mockAdb,
          'device_1',
          resourceId: 'com.example:id/button',
        );

        expect(result, isNull);
        verifyZeroInteractions(mockEngine);
        verifyNever(() => mockAdb.captureScreenshotBytes(any()));
      },
    );
  });
}
