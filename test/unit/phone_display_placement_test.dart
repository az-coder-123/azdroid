import 'package:desk_droid/features/streaming/presentation/widgets/phone_display_placement.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('placePhoneDisplay', () {
    test('landscape stream fills the area width and never exceeds it', () {
      final rect = placePhoneDisplay(
        area: const Size(1700, 940),
        windowWidth: 1770,
        aspectRatio: 1920 / 1080,
      );
      expect(rect.width, closeTo(1671.1, 0.1));
      expect(rect.right, lessThanOrEqualTo(1700));
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.width / rect.height, closeTo(1920 / 1080, 1e-9));
    });

    test('portrait stream is centered in the whole window when it fits', () {
      final rect = placePhoneDisplay(
        area: const Size(1700, 900),
        windowWidth: 1770,
        aspectRatio: 1080 / 2400,
      );
      expect(rect.height, 900);
      expect(rect.center.dx, closeTo(1770 / 2, 1e-9));
    });

    test('moves left only as far as needed to stay inside the area', () {
      final rect = placePhoneDisplay(
        area: const Size(450, 900),
        windowWidth: 520,
        aspectRatio: 1080 / 2400,
      );
      // Window-centered would be left 57.5 (right 462.5 > 450).
      expect(rect.left, closeTo(45, 1e-9));
      expect(rect.right, closeTo(450, 1e-9));
    });

    test('returns an empty rect for an empty area or invalid ratio', () {
      expect(
        placePhoneDisplay(area: Size.zero, windowWidth: 100, aspectRatio: 0.5),
        Rect.zero,
      );
      expect(
        placePhoneDisplay(
          area: const Size(100, 100),
          windowWidth: 100,
          aspectRatio: double.nan,
        ),
        Rect.zero,
      );
    });

    test('centers correctly in window with leftOffset', () {
      final rect = placePhoneDisplay(
        area: const Size(1600, 900),
        windowWidth: 1760,
        aspectRatio: 1080 / 2400,
        leftOffset: 80,
      );
      expect(rect.height, 900);
      expect(rect.center.dx + 80, closeTo(1760 / 2, 1e-9));
    });
  });
}
