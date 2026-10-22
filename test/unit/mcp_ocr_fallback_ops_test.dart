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
  });

  group('McpOcrFallbackOps Tests', () {
    test('returns null when query text is empty or blank', () async {
      final result = await McpOcrFallbackOps.findElementViaOcr(
        mockAdb,
        'device_1',
        text: '   ',
        ocrEngine: mockEngine,
      );
      expect(result, isNull);
      verifyZeroInteractions(mockEngine);
    });

    test('returns null when engine is not available', () async {
      when(() => mockEngine.isAvailable()).thenAnswer((_) async => false);

      final result = await McpOcrFallbackOps.findElementViaOcr(
        mockAdb,
        'device_1',
        text: 'Login',
        ocrEngine: mockEngine,
      );
      expect(result, isNull);
      verify(() => mockEngine.isAvailable()).called(1);
      verifyZeroInteractions(mockAdb);
    });

    test('returns null when screenshot capture fails', () async {
      when(() => mockEngine.isAvailable()).thenAnswer((_) async => true);
      when(() => mockAdb.captureScreenshotBytes('device_1'))
          .thenAnswer((_) async => null);

      final result = await McpOcrFallbackOps.findElementViaOcr(
        mockAdb,
        'device_1',
        text: 'Login',
        ocrEngine: mockEngine,
      );
      expect(result, isNull);
    });

    test(
      'returns null when recognition produces no elements or no match',
      () async {
        when(() => mockEngine.isAvailable()).thenAnswer((_) async => true);
        when(() => mockAdb.captureScreenshotBytes('device_1'))
            .thenAnswer((_) async => [10, 20, 30]);
        when(() => mockEngine.recognize([10, 20, 30]))
            .thenAnswer((_) async => const []);

        final result = await McpOcrFallbackOps.findElementViaOcr(
          mockAdb,
          'device_1',
          text: 'Login',
          ocrEngine: mockEngine,
        );
        expect(result, isNull);
      },
    );

    test('finds exact text match and formats standard MCP response', () async {
      when(() => mockEngine.isAvailable()).thenAnswer((_) async => true);
      when(() => mockAdb.captureScreenshotBytes('device_1'))
          .thenAnswer((_) async => [1, 2, 3]);
      when(() => mockAdb.getDisplaySize('device_1'))
          .thenAnswer((_) async => const Point(1080, 1920));
      when(() => mockEngine.recognize([1, 2, 3])).thenAnswer(
        (_) async => const [
          McpOcrElement(
            text: 'Sign Up',
            left: 100,
            top: 200,
            width: 150,
            height: 50,
            confidence: 0.98,
          ),
          McpOcrElement(
            text: 'Log In',
            left: 100,
            top: 300,
            width: 150,
            height: 50,
            confidence: 0.95,
          ),
        ],
      );

      final result = await McpOcrFallbackOps.findElementViaOcr(
        mockAdb,
        'device_1',
        text: 'Log In',
        ocrEngine: mockEngine,
      );

      expect(result, isNotNull);
      expect(result!['id'], equals(-1));
      expect(result['text'], equals('Log In'));
      expect(result['class'], equals('OcrTextElement'));
      expect(result['source'], equals('ocr_stage_3'));
      expect(result['centerPixels'], equals({'x': 175, 'y': 325}));
      expect(result['confidence'], equals(0.95));
    });

    test('finds contains text match when exact match is absent', () async {
      when(() => mockEngine.isAvailable()).thenAnswer((_) async => true);
      when(() => mockAdb.captureScreenshotBytes('device_1'))
          .thenAnswer((_) async => [1, 2, 3]);
      when(() => mockAdb.getDisplaySize('device_1'))
          .thenAnswer((_) async => const Point(1080, 1920));
      when(() => mockEngine.recognize([1, 2, 3])).thenAnswer(
        (_) async => const [
          McpOcrElement(
            text: 'Welcome back to Azdroid workstation',
            left: 50,
            top: 150,
            width: 500,
            height: 60,
            confidence: 0.94,
          ),
        ],
      );

      final result = await McpOcrFallbackOps.findElementViaOcr(
        mockAdb,
        'device_1',
        text: 'Azdroid workstation',
        ocrEngine: mockEngine,
      );

      expect(result, isNotNull);
      expect(result!['text'], equals('Welcome back to Azdroid workstation'));
      expect(result['centerPixels'], equals({'x': 300, 'y': 180}));
      expect(result['source'], equals('ocr_stage_3'));
    });
  });
}
