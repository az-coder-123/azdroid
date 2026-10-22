import 'dart:convert';
import 'dart:typed_data';

import 'package:desk_droid/features/mcp/data/handlers/mcp_tool_executor.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_adb_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mocktail/mocktail.dart';

class MockMcpAdbClient extends Mock implements McpAdbClient {}

void main() {
  late MockMcpAdbClient mockAdb;
  late McpToolExecutor executor;

  setUp(() {
    mockAdb = MockMcpAdbClient();
    executor = McpToolExecutor(adbClient: mockAdb);
  });

  group('android_take_screenshot ROI Crop & Format Tests', () {
    test('captures and crops screenshot with ROI percentage ratio', () async {
      final image = img.Image(width: 1000, height: 2000);
      img.fill(image, color: img.ColorRgb8(20, 40, 60));
      final pngBytes = img.encodePng(image);

      when(() => mockAdb.captureScreenshotBytes('192.168.1.100:5555'))
          .thenAnswer((_) async => pngBytes);

      final res = await executor.execute('android_take_screenshot', {
        'deviceSerial': '192.168.1.100:5555',
        'cropRatio': {'x': 0.1, 'y': 0.2, 'width': 0.5, 'height': 0.3},
      });

      expect(res.isError, isFalse);
      expect(res.content.first.type, equals('image'));
      final base64Str = res.content.first.data;
      final decodedBytes = base64Decode(base64Str!);
      final croppedImage = img.decodeImage(Uint8List.fromList(decodedBytes));
      expect(croppedImage, isNotNull);
      expect(croppedImage!.width, equals(500));
      expect(croppedImage.height, equals(600));
    });

    test(
      'captures and compresses screenshot as JPEG with correct mimeType',
      () async {
        final image = img.Image(width: 400, height: 800);
        img.fill(image, color: img.ColorRgb8(10, 20, 30));
        final pngBytes = img.encodePng(image);

        when(() => mockAdb.captureScreenshotBytes('192.168.1.100:5555'))
            .thenAnswer((_) async => pngBytes);

        final res = await executor.execute('android_take_screenshot', {
          'deviceSerial': '192.168.1.100:5555',
          'format': 'jpeg',
          'quality': 60,
        });

        expect(res.isError, isFalse);
        expect(res.content.first.type, equals('image'));
        expect(res.content.first.mimeType, equals('image/jpeg'));
        final base64Str = res.content.first.data;
        final decodedBytes = base64Decode(base64Str!);
        expect(decodedBytes[0], equals(0xFF));
        expect(decodedBytes[1], equals(0xD8));
      },
    );
  });

  // The scrcpy touch session is off in tests (flutter_test_config.dart), so
  // these exercise the one-finger fallback. Centers reach it in pixels of a
  // 1000×2000 screen; the scrcpy path is in mcp_multitouch_test.dart.
  group('pinch and rotate fallback', () {
    const serial = '192.168.1.100:5555';
    setUp(() {
      when(() => mockAdb.getDisplaySize(serial))
          .thenAnswer((_) async => const Point(1000, 2000));
    });

    test('zoom-in pinch with the scaleFactor alias', () async {
      when(
        () => mockAdb.pinchGesture(
          serial,
          scale: 1.8,
          centerX: 500,
          centerY: 1000,
          durationMs: 400,
        ),
      ).thenAnswer((_) async => true);

      final res = await executor.execute('android_pinch_gesture', {
        'deviceSerial': serial,
        'scaleFactor': 1.8,
      });

      expect(res.isError, isFalse);
      expect(
        res.content.first.text,
        startsWith('One-finger approximation of pinch (scale 1.8)'),
      );
      expect(res.content.first.text, contains('scrcpy is off in tests'));
    });

    test('zoom-out pinch with a custom center and duration', () async {
      when(
        () => mockAdb.pinchGesture(
          serial,
          scale: 0.5,
          centerX: 300,
          centerY: 1400,
          durationMs: 500,
        ),
      ).thenAnswer((_) async => true);

      final res = await executor.execute('android_pinch_gesture', {
        'deviceSerial': serial,
        'zoom': 0.5,
        'center_x': 0.3,
        'center_y': 0.7,
        'durationMs': 500,
      });

      expect(res.isError, isFalse, reason: res.content.first.text);
    });

    test('rotation with aliases, custom center, and radius', () async {
      when(
        () => mockAdb.rotateGesture(
          serial,
          angleDegrees: -45.0,
          centerX: 400,
          centerY: 1200,
          radius: 150.0,
          durationMs: 600,
        ),
      ).thenAnswer((_) async => true);

      final res = await executor.execute('android_rotate_gesture', {
        'deviceSerial': serial,
        'angle': -45.0,
        'center_x': 0.4,
        'center_y': 0.6,
        'r': 150.0,
        'duration': 600,
      });

      expect(res.isError, isFalse, reason: res.content.first.text);
      expect(res.content.first.text, contains('rotation (-45.0°)'));
    });

    test('a failed fallback is an error', () async {
      when(
        () => mockAdb.rotateGesture(
          serial,
          angleDegrees: 90.0,
          centerX: 500,
          centerY: 1000,
          radius: 200.0,
          durationMs: 400,
        ),
      ).thenAnswer((_) async => false);

      final res = await executor.execute('android_rotate_gesture', {
        'deviceSerial': serial,
        'angleDegrees': 90.0,
      });

      expect(res.isError, isTrue);
    });
  });

  group('android_scroll Tests', () {
    test(
      'executes directional scroll (down, fast fling) via McpAdbClient',
      () async {
        when(
          () => mockAdb.scroll(
            '192.168.1.100:5555',
            direction: 'down',
            distance: 0.7,
            speed: 'fast',
            start: null,
            end: null,
            durationMs: null,
          ),
        ).thenAnswer((_) async => true);

        final res = await executor.execute('android_scroll', {
          'deviceSerial': '192.168.1.100:5555',
          'direction': 'down',
          'distance': 0.7,
          'speed': 'fast',
        });

        expect(res.isError, isFalse);
        expect(
          res.content.first.text,
          contains(
            'Scrolled down (fast, distance: 0.7) on 192.168.1.100:5555.',
          ),
        );
      },
    );
  });
}
