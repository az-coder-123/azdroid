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

    final hasCrop = cropX != null ||
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

      int x = cropXRatio != null
          ? (cropXRatio * imgW).round()
          : (cropX ?? 0);
      int y = cropYRatio != null
          ? (cropYRatio * imgH).round()
          : (cropY ?? 0);
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

  /// Parses crop and compression parameters from tool [arguments] and applies them to [rawBytes].
  static List<int> processFromArguments(
    List<int> rawBytes,
    Map<String, dynamic> arguments,
  ) {
    final crop = arguments['crop'] is Map ? arguments['crop'] as Map : null;
    final cropRatio =
        arguments['cropRatio'] is Map ? arguments['cropRatio'] as Map : null;

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

    final cropX = parseInt(crop?['x'] ?? arguments['cropX'] ?? arguments['x']);
    final cropY = parseInt(crop?['y'] ?? arguments['cropY'] ?? arguments['y']);
    final cropW = parseInt(
      crop?['width'] ??
          crop?['w'] ??
          arguments['cropWidth'] ??
          arguments['width'] ??
          arguments['w'],
    );
    final cropH = parseInt(
      crop?['height'] ??
          crop?['h'] ??
          arguments['cropHeight'] ??
          arguments['height'] ??
          arguments['h'],
    );

    final cropXRatio = parseDouble(
      cropRatio?['x'] ??
          arguments['cropXRatio'] ??
          arguments['xRatio'] ??
          arguments['xPercent'],
    );
    final cropYRatio = parseDouble(
      cropRatio?['y'] ??
          arguments['cropYRatio'] ??
          arguments['yRatio'] ??
          arguments['yPercent'],
    );
    final cropWRatio = parseDouble(
      cropRatio?['width'] ??
          cropRatio?['w'] ??
          arguments['cropWidthRatio'] ??
          arguments['widthRatio'] ??
          arguments['widthPercent'],
    );
    final cropHRatio = parseDouble(
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
