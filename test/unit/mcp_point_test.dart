import 'dart:io';

import 'package:desk_droid/features/mcp/data/services/mcp_adb_client.dart';
import 'package:desk_droid/features/mcp/data/utils/mcp_argument_helper.dart';
import 'package:desk_droid/features/mcp/data/utils/mcp_point.dart';
import 'package:desk_droid/features/mcp/data/utils/mcp_point_arguments.dart';
import 'package:desk_droid/features/mcp/data/utils/mcp_scroll_path.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAdb extends Mock implements McpAdbClient {}

void main() {
  const width = 1080;
  const height = 2400;

  group('reading points from tool arguments', () {
    test('ratio beats pixel beats raw, per axis, with aliases', () {
      final point = <String, dynamic>{
        'x': 100,
        'xRatio': 0.5,
        'y': 200,
        'y_pixel': 777,
      }.getPoint();
      expect(point.x, const McpAxis(0.5, McpUnit.ratio));
      expect(point.y, const McpAxis(777, McpUnit.pixel));

      final custom = <String, dynamic>{
        'startX_percent': 0.25,
        'startYCoord': 640,
      }.getPoint(xKey: 'startX', yKey: 'startY');
      expect(custom.x.unit, McpUnit.ratio);
      expect(custom.y, const McpAxis(640, McpUnit.auto));
    });

    test('a missing axis throws, or gives null when optional', () {
      expect(
        () => <String, dynamic>{'x': 100}.getPoint(),
        throwsA(isA<McpArgumentException>()),
      );
      expect(<String, dynamic>{'x': 100}.getOptionalPoint(), isNull);
    });
  });

  group('resolving to pixels', () {
    (int, int) px(McpPoint p) => p.toPixels(width, height);

    test('explicit pixels are never scaled, even within 0-1', () {
      // Bug before 2026-10-22: xPixel 1 / yPixel 1 tapped the bottom-right.
      final point = McpPoint.pixels(1, 1);
      expect(px(point), (1, 1));
      expect(point.needsDisplaySize, isFalse);
    });

    test('mixed explicit units resolve per axis', () {
      // Bug before 2026-10-22: xRatio 0.5 + yPixel 600 tapped pixel (1, 600).
      final point = <String, dynamic>{'xRatio': 0.5, 'yPixel': 600}.getPoint();
      expect(px(point), (540, 600));
    });

    test('raw values are fractions only when both are within 0-1', () {
      expect(px(<String, dynamic>{'x': 0.5, 'y': 0.25}.getPoint()), (540, 600));
      expect(px(<String, dynamic>{'x': 1.0, 'y': 1.0}.getPoint()), (
        1080,
        2400,
      ));
      expect(px(<String, dynamic>{'x': 0.5, 'y': 900}.getPoint()), (1, 900));
      expect(px(<String, dynamic>{'x': 540, 'y': 1200}.getPoint()), (
        540,
        1200,
      ));
    });

    test('a raw axis next to an explicit one follows its own value', () {
      final point = <String, dynamic>{'x': 0.5, 'yPixel': 900}.getPoint();
      expect(px(point), (540, 900));
    });
  });

  test('scroll paths move the finger against the content', () {
    final down = mcpScrollPath('down', 0.6);
    expect(down.start.toPixels(width, height), (540, 1920));
    expect(down.end.toPixels(width, height), (540, 480));
    expect(mcpScrollDurationMs('fling', null), 80);
    expect(mcpScrollDurationMs('slow', 900), 900);
  });

  group('adb input', () {
    late _MockAdb adb;
    late List<List<String>> commands;

    setUp(() {
      adb = _MockAdb();
      commands = [];
      when(() => adb.run(any())).thenAnswer((invocation) async {
        final args = invocation.positionalArguments.first as List<String>;
        commands.add(args);
        final out = args.contains('wm') ? 'Physical size: 1080x2400' : '';
        return ProcessResult(0, 0, out, '');
      });
    });

    test('pixel taps go out as given, without a display-size query', () async {
      await McpAdbInputOps.tap(adb, 'pixel-serial', McpPoint.pixels(1, 1));
      expect(commands, [
        ['-s', 'pixel-serial', 'shell', 'input', 'tap', '1', '1'],
      ]);
    });

    test('a swipe resolves each end on its own', () async {
      await McpAdbInputOps.swipe(
        adb,
        'swipe-serial',
        McpPoint.pixels(100, 200),
        McpPoint.ratio(0.5, 0.5),
        300,
      );
      expect(commands.last, [
        '-s',
        'swipe-serial',
        'shell',
        'input',
        'swipe',
        '100',
        '200',
        '540',
        '1200',
        '300',
      ]);
    });
  });
}
