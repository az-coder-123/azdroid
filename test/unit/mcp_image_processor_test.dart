import 'dart:typed_data';

import 'package:desk_droid/features/mcp/data/services/mcp_image_processor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  group('McpImageProcessor Tests', () {
    late List<int> samplePngBytes;

    setUp(() {
      final image = img.Image(width: 200, height: 400);
      img.fill(image, color: img.ColorRgb8(100, 150, 200));
      samplePngBytes = img.encodePng(image);
    });

    test('returns original bytes when no crop or format change requested', () {
      final out = McpImageProcessor.processScreenshot(samplePngBytes);
      expect(out, equals(samplePngBytes));
    });

    test('crops using exact pixel bounds', () {
      final out = McpImageProcessor.processScreenshot(
        samplePngBytes,
        cropX: 50,
        cropY: 100,
        cropWidth: 80,
        cropHeight: 120,
      );
      final decoded = img.decodeImage(Uint8List.fromList(out));
      expect(decoded, isNotNull);
      expect(decoded!.width, equals(80));
      expect(decoded.height, equals(120));
    });

    test('crops using percentage ratio bounds', () {
      final out = McpImageProcessor.processScreenshot(
        samplePngBytes,
        cropXRatio: 0.1, // 20px
        cropYRatio: 0.2, // 80px
        cropWidthRatio: 0.5, // 100px
        cropHeightRatio: 0.4, // 160px
      );
      final decoded = img.decodeImage(Uint8List.fromList(out));
      expect(decoded, isNotNull);
      expect(decoded!.width, equals(100));
      expect(decoded.height, equals(160));
    });

    test('converts format to compressed JPEG', () {
      final out = McpImageProcessor.processScreenshot(
        samplePngBytes,
        format: 'jpeg',
        quality: 75,
      );
      // JPEG files start with bytes 0xFF, 0xD8
      expect(out.length, greaterThan(2));
      expect(out[0], equals(0xFF));
      expect(out[1], equals(0xD8));
    });

    test('processFromArguments handles nested crop map and ratios', () {
      final args = {
        'crop': {'x': 10, 'y': 20, 'width': 60, 'height': 80},
        'format': 'png',
      };
      final out = McpImageProcessor.processFromArguments(samplePngBytes, args);
      final decoded = img.decodeImage(Uint8List.fromList(out));
      expect(decoded, isNotNull);
      expect(decoded!.width, equals(60));
      expect(decoded.height, equals(80));
    });

    test('processFromArguments handles cropRatio map', () {
      final args = {
        'cropRatio': {'x': 0.0, 'y': 0.5, 'width': 1.0, 'height': 0.5},
        'format': 'png',
      };
      final out = McpImageProcessor.processFromArguments(samplePngBytes, args);
      final decoded = img.decodeImage(Uint8List.fromList(out));
      expect(decoded, isNotNull);
      expect(decoded!.width, equals(200));
      expect(decoded.height, equals(200));
    });

    test('processFromArguments handles normalized ratios specified directly inside crop map', () {
      final args = {
        'crop': {'x': 0.0, 'y': 0.5, 'width': 1.0, 'height': 0.5},
        'format': 'png',
      };
      final out = McpImageProcessor.processFromArguments(samplePngBytes, args);
      final decoded = img.decodeImage(Uint8List.fromList(out));
      expect(decoded, isNotNull);
      expect(decoded!.width, equals(200));
      expect(decoded.height, equals(200));
    });

    test('isJpeg correctly identifies jpeg format variations', () {
      expect(McpImageProcessor.isJpeg('jpeg'), isTrue);
      expect(McpImageProcessor.isJpeg('JPEG'), isTrue);
      expect(McpImageProcessor.isJpeg('jpg'), isTrue);
      expect(McpImageProcessor.isJpeg('JPG '), isTrue);
      expect(McpImageProcessor.isJpeg('png'), isFalse);
      expect(McpImageProcessor.isJpeg(null), isFalse);
    });
  });
}
