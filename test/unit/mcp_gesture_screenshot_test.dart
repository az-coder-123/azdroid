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
  });

  group('android_pinch_gesture Tests', () {
    test('executes zoom-in pinch gesture via McpAdbClient', () async {
      when(
        () => mockAdb.pinchGesture(
          '192.168.1.100:5555',
          scale: 2.0,
          centerX: 0.5,
          centerY: 0.5,
          durationMs: 400,
        ),
      ).thenAnswer((_) async => true);

      final res = await executor.execute('android_pinch_gesture', {
        'deviceSerial': '192.168.1.100:5555',
        'scale': 2.0,
      });

      expect(res.isError, isFalse);
      expect(
        res.content.first.text,
        contains('Injected pinch gesture (scale: 2.0'),
      );
    });

    test(
      'executes zoom-out pinch gesture with custom center coordinates',
      () async {
        when(
          () => mockAdb.pinchGesture(
            '192.168.1.100:5555',
            scale: 0.5,
            centerX: 0.3,
            centerY: 0.7,
            durationMs: 500,
          ),
        ).thenAnswer((_) async => true);

        final res = await executor.execute('android_pinch_gesture', {
          'deviceSerial': '192.168.1.100:5555',
          'zoom': 0.5,
          'center_x': 0.3,
          'center_y': 0.7,
          'durationMs': 500,
        });

        expect(res.isError, isFalse);
        expect(
          res.content.first.text,
          contains('Injected pinch gesture (scale: 0.5, center: (0.3, 0.7))'),
        );
      },
    );
  });
}
