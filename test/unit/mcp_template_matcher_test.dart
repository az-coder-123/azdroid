import 'dart:math';

import 'package:desk_droid/features/mcp/data/services/mcp_template_matcher.dart';
import 'package:desk_droid/features/mcp/data/utils/mcp_argument_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

/// A busy screen (smooth background with random blobs), like a game frame.
img.Image _screen(int width, int height, int seed) {
  final rnd = Random(seed);
  final screen = img.Image(width: width, height: height);
  for (final p in screen) {
    p
      ..r = (p.x * 255 ~/ width)
      ..g = (p.y * 255 ~/ height)
      ..b = 90;
  }
  for (var i = 0; i < 120; i++) {
    img.fillCircle(
      screen,
      x: rnd.nextInt(width),
      y: rnd.nextInt(height),
      radius: 6 + rnd.nextInt(30),
      color: img.ColorRgb8(
        rnd.nextInt(256),
        rnd.nextInt(256),
        rnd.nextInt(256),
      ),
    );
  }
  return screen;
}

/// A sprite with detail: a ring and a cross.
img.Image _sprite(int size) {
  final s = img.Image(width: size, height: size);
  img.fill(s, color: img.ColorRgb8(20, 20, 20));
  img.drawCircle(
    s,
    x: size ~/ 2,
    y: size ~/ 2,
    radius: size ~/ 3,
    color: img.ColorRgb8(250, 200, 0),
  );
  img.drawLine(
    s,
    x1: 0,
    y1: 0,
    x2: size - 1,
    y2: size - 1,
    color: img.ColorRgb8(0, 220, 255),
    thickness: 3,
  );
  img.fillRect(
    s,
    x1: size ~/ 4,
    y1: size ~/ 6,
    x2: size ~/ 2,
    y2: size ~/ 3,
    color: img.ColorRgb8(255, 255, 255),
  );
  return s;
}

void main() {
  test('finds a crop of the screen at its exact position', () {
    final screen = _screen(720, 1600, 1);
    img.compositeImage(screen, _sprite(64), dstX: 401, dstY: 903);
    final template = img.copyCrop(
      screen,
      x: 401,
      y: 903,
      width: 64,
      height: 64,
    );
    final match = McpTemplateMatcher.find(screen, template);

    expect(match.score, greaterThan(0.99));
    expect((match.left, match.top), (401, 903));
    expect((match.centerX, match.centerY), (433, 935));
    expect(match.scale, 1.0);
  });

  test('finds a sprite drawn twice as large as its file', () {
    final screen = _screen(1080, 2340, 2);
    final sprite = _sprite(48);
    img.compositeImage(
      screen,
      img.copyResize(sprite, width: 96, height: 96),
      dstX: 700,
      dstY: 300,
    );
    final match = McpTemplateMatcher.find(screen, sprite);

    expect(match.score, greaterThan(0.9));
    expect(match.scale, 2.0);
    expect((match.left - 700).abs(), lessThanOrEqualTo(2));
    expect((match.top - 300).abs(), lessThanOrEqualTo(2));
  });

  test('a large template stays fast and exact', () {
    final screen = _screen(1080, 2340, 3);
    img.compositeImage(screen, _sprite(400), dstX: 300, dstY: 1200);
    final template = img.copyCrop(
      screen,
      x: 300,
      y: 1200,
      width: 400,
      height: 400,
    );
    final watch = Stopwatch()..start();
    final match = McpTemplateMatcher.find(screen, template);
    expect((match.left, match.top), (300, 1200));
    expect(watch.elapsedMilliseconds, lessThan(5000));
  });

  test('an absent sprite scores low', () {
    final screen = _screen(720, 1600, 4);
    final match = McpTemplateMatcher.find(screen, _sprite(64));
    expect(match.score, lessThan(0.8));
  });

  test('a flat template is rejected', () {
    final flat = img.Image(width: 30, height: 30);
    img.fill(flat, color: img.ColorRgb8(10, 10, 10));
    expect(
      () => McpTemplateMatcher.find(_screen(300, 600, 5), flat),
      throwsA(isA<McpArgumentException>()),
    );
  });
}
