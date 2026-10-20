import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Service for region-of-interest (ROI) cropping, format conversion,
/// and compression of Android screenshot bytes.
class McpImageProcessor {
  const McpImageProcessor._();

  /// Crops and/or converts [rawBytes] according to pixel or normalized parameters.
  /// If no crop or format changes are requested, returns [rawBytes] directly.
  static List<int> processScreenshot(
    List<int> rawBytes, {
    int? cropX,
    int? cropY,
    int? cropWidth,
    int? cropHeight,
    double? cropXRatio,
    double? cropYRatio,
    double? cropWidthRatio,
    double? cropHeightRatio,
    String format = 'png',
    int quality = 80,
  }) {
    if (rawBytes.isEmpty) return rawBytes;

    final hasCrop =
        cropX != null ||
        cropY != null ||
        cropWidth != null ||
        cropHeight != null ||
        cropXRatio != null ||
        cropYRatio != null ||
        cropWidthRatio != null ||
        cropHeightRatio != null;

    final targetFormat = format.toLowerCase().trim();
    final isJpeg = targetFormat == 'jpeg' || targetFormat == 'jpg';

    // If untouched PNG requested, return immediately without decoding
    if (!hasCrop && !isJpeg) {
      return rawBytes;
    }

    final decoded = img.decodeImage(Uint8List.fromList(rawBytes));
    if (decoded == null) return rawBytes;

    img.Image result = decoded;

    if (hasCrop) {
      final imgW = decoded.width;
      final imgH = decoded.height;

      int x = cropXRatio != null ? (cropXRatio * imgW).round() : (cropX ?? 0);
      int y = cropYRatio != null ? (cropYRatio * imgH).round() : (cropY ?? 0);
      int w = cropWidthRatio != null
          ? (cropWidthRatio * imgW).round()
          : (cropWidth ?? (imgW - x));
      int h = cropHeightRatio != null
          ? (cropHeightRatio * imgH).round()
          : (cropHeight ?? (imgH - y));

      x = x.clamp(0, imgW - 1);
      y = y.clamp(0, imgH - 1);
      w = w.clamp(1, imgW - x);
      h = h.clamp(1, imgH - y);

      result = img.copyCrop(decoded, x: x, y: y, width: w, height: h);
    }

    if (isJpeg) {
      return img.encodeJpg(result, quality: quality.clamp(1, 100));
    }
    return img.encodePng(result);
  }

  /// Returns true if [format] denotes a JPEG image.
  static bool isJpeg(dynamic format) {
    if (format == null) return false;
    final f = format.toString().toLowerCase().trim();
    return f == 'jpeg' || f == 'jpg';
  }

  /// Parses crop and compression parameters from tool [arguments] and applies them to [rawBytes].
  static List<int> processFromArguments(
    List<int> rawBytes,
    Map<String, dynamic> arguments,
  ) {
    final crop = arguments['crop'] is Map ? arguments['crop'] as Map : null;
    final cropRatio = arguments['cropRatio'] is Map
        ? arguments['cropRatio'] as Map
        : null;

    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }

    double? parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    // Detect if crop map specifies normalized coordinates (0.0..1.0)
    final rawW = parseDouble(crop?['width'] ?? crop?['w']);
    final rawH = parseDouble(crop?['height'] ?? crop?['h']);
    final cropHasRatios =
        (rawW != null && rawW <= 1.0 && rawW > 0.0) ||
        (rawH != null && rawH <= 1.0 && rawH > 0.0) ||
        crop?['xRatio'] != null ||
        crop?['yRatio'] != null ||
        crop?['widthRatio'] != null ||
        crop?['heightRatio'] != null;

    double? cropXRatio;
    double? cropYRatio;
    double? cropWRatio;
    double? cropHRatio;
    int? cropX;
    int? cropY;
    int? cropW;
    int? cropH;

    if (cropHasRatios) {
      cropXRatio = parseDouble(
        crop?['xRatio'] ??
            crop?['x'] ??
            arguments['cropXRatio'] ??
            arguments['xRatio'],
      );
      cropYRatio = parseDouble(
        crop?['yRatio'] ??
            crop?['y'] ??
            arguments['cropYRatio'] ??
            arguments['yRatio'],
      );
      cropWRatio = parseDouble(
        crop?['widthRatio'] ??
            crop?['w'] ??
            crop?['width'] ??
            arguments['cropWidthRatio'] ??
            arguments['widthRatio'],
      );
      cropHRatio = parseDouble(
        crop?['heightRatio'] ??
            crop?['h'] ??
            crop?['height'] ??
            arguments['cropHeightRatio'] ??
            arguments['heightRatio'],
      );
    } else {
      cropX = parseInt(crop?['x'] ?? arguments['cropX'] ?? arguments['x']);
      cropY = parseInt(crop?['y'] ?? arguments['cropY'] ?? arguments['y']);
      cropW = parseInt(
        crop?['width'] ??
            crop?['w'] ??
            arguments['cropWidth'] ??
            arguments['width'] ??
            arguments['w'],
      );
      cropH = parseInt(
        crop?['height'] ??
            crop?['h'] ??
            arguments['cropHeight'] ??
            arguments['height'] ??
            arguments['h'],
      );
    }

    cropXRatio ??= parseDouble(
      cropRatio?['x'] ??
          arguments['cropXRatio'] ??
          arguments['xRatio'] ??
          arguments['xPercent'],
    );
    cropYRatio ??= parseDouble(
      cropRatio?['y'] ??
          arguments['cropYRatio'] ??
          arguments['yRatio'] ??
          arguments['yPercent'],
    );
    cropWRatio ??= parseDouble(
      cropRatio?['width'] ??
          cropRatio?['w'] ??
          arguments['cropWidthRatio'] ??
          arguments['widthRatio'] ??
          arguments['widthPercent'],
    );
    cropHRatio ??= parseDouble(
      cropRatio?['height'] ??
          cropRatio?['h'] ??
          arguments['cropHeightRatio'] ??
          arguments['heightRatio'] ??
          arguments['heightPercent'],
    );

    final format = (arguments['format'] ?? 'png').toString();
    final quality = parseInt(arguments['quality']) ?? 80;

    return processScreenshot(
      rawBytes,
      cropX: cropX,
      cropY: cropY,
      cropWidth: cropW,
      cropHeight: cropH,
      cropXRatio: cropXRatio,
      cropYRatio: cropYRatio,
      cropWidthRatio: cropWRatio,
      cropHeightRatio: cropHRatio,
      format: format,
      quality: quality,
    );
  }
}
