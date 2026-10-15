import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:desk_droid/features/productivity/data/utils/image_crop_util.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ImageCropUtil', () {
    test('decodes and crops PNG sub-region with pixel precision', () async {
      // Create a test 100x100 red canvas image
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawRect(
        const ui.Rect.fromLTWH(0, 0, 100, 100),
        ui.Paint()..color = const ui.Color(0xFFFF0000),
      );
      final picture = recorder.endRecording();
      final image = await picture.toImage(100, 100);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final originalPngBytes = byteData!.buffer.asUint8List();

      // Crop central region: 25..75 normalized (0.25, 0.25, 0.75, 0.75) -> 50x50 px
      final croppedBytes = await ImageCropUtil.cropPng(
        originalPngBytes,
        const ui.Rect.fromLTRB(0.25, 0.25, 0.75, 0.75),
      );

      expect(croppedBytes, isNotEmpty);

      // Verify cropped dimensions
      final codec = await ui.instantiateImageCodec(croppedBytes);
      final frame = await codec.getNextFrame();
      expect(frame.image.width, 50);
      expect(frame.image.height, 50);
    });
  });
}
