import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Utility for decoding and cropping PNG images to a normalized sub-region.
class ImageCropUtil {
  const ImageCropUtil._();

  /// Crops [pngBytes] to the specified [normalizedRect] ($0.0 \to 1.0$)
  /// and returns freshly encoded lossless PNG bytes.
  static Future<Uint8List> cropPng(
    Uint8List pngBytes,
    Rect normalizedRect,
  ) async {
    final codec = await ui.instantiateImageCodec(pngBytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final imgW = image.width.toDouble();
    final imgH = image.height.toDouble();

    // Map normalized coordinates into source pixel coordinates
    final srcX = (normalizedRect.left * imgW).clamp(0.0, imgW - 1.0);
    final srcY = (normalizedRect.top * imgH).clamp(0.0, imgH - 1.0);
    final srcW = (normalizedRect.width * imgW).clamp(1.0, imgW - srcX);
    final srcH = (normalizedRect.height * imgH).clamp(1.0, imgH - srcY);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(srcX, srcY, srcW, srcH),
      Rect.fromLTWH(0, 0, srcW, srcH),
      Paint(),
    );

    final picture = recorder.endRecording();
    final croppedImage = await picture.toImage(srcW.round(), srcH.round());
    final byteData = await croppedImage.toByteData(
      format: ui.ImageByteFormat.png,
    );

    image.dispose();
    croppedImage.dispose();

    if (byteData == null) {
      throw const FormatException('Failed to encode cropped image to PNG');
    }

    return byteData.buffer.asUint8List();
  }
}
