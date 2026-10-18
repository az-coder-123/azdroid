import 'package:desk_droid/features/streaming/presentation/widgets/mirroring_central_viewport.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _displayKey = Key('display');
const _toolbarKey = Key('toolbar');

Future<void> _pump(
  WidgetTester tester, {
  required Size window,
  required double aspectRatio,
  required double toolbarWidth,
}) async {
  tester.view.physicalSize = window;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: MirroringCentralViewport(
        aspectRatio: aspectRatio,
        display: const ColoredBox(key: _displayKey, color: Colors.black),
        sideToolbar: SizedBox(
          key: _toolbarKey,
          width: toolbarWidth,
          height: 400,
        ),
      ),
    ),
  );
}

void main() {
  // Toolbar widths seen in practice: compact density (macOS) and standard.
  const toolbarWidths = [44.0, 54.0, 62.0];
  const windows = [Size(1850, 940), Size(900, 600), Size(420, 700)];
  const ratios = [1920 / 1080, 1080 / 2336, 1.0];

  for (final toolbarWidth in toolbarWidths) {
    for (final window in windows) {
      for (final ratio in ratios) {
        testWidgets('no overflow: toolbar $toolbarWidth, window $window, ratio '
            '${ratio.toStringAsFixed(2)}', (tester) async {
          await _pump(
            tester,
            window: window,
            aspectRatio: ratio,
            toolbarWidth: toolbarWidth,
          );
          expect(tester.takeException(), isNull);

          final display = tester.getRect(find.byKey(_displayKey));
          final toolbar = tester.getRect(find.byKey(_toolbarKey));
          expect(display.width / display.height, closeTo(ratio, 1e-6));
          expect(
            display.right + MirroringCentralViewport.toolbarGap,
            lessThanOrEqualTo(toolbar.left + 1e-6),
          );
          expect(toolbar.right, lessThanOrEqualTo(window.width + 1e-6));
        });
      }
    }
  }

  group('dual toolbars layout', () {
    const leftKey = Key('leftToolbar');
    const rightKey = Key('rightToolbar');

    testWidgets(
      'lays out leftToolbar, display, and rightToolbar without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          const MaterialApp(
            home: MirroringCentralViewport(
              aspectRatio: 1080 / 2400,
              display: ColoredBox(key: _displayKey, color: Colors.black),
              leftToolbar: SizedBox(key: leftKey, width: 48, height: 400),
              sideToolbar: SizedBox(key: rightKey, width: 48, height: 400),
            ),
          ),
        );
        expect(tester.takeException(), isNull);

        final leftRect = tester.getRect(find.byKey(leftKey));
        final displayRect = tester.getRect(find.byKey(_displayKey));
        final rightRect = tester.getRect(find.byKey(rightKey));

        expect(
          leftRect.right + MirroringCentralViewport.toolbarGap,
          lessThanOrEqualTo(displayRect.left + 1e-6),
        );
        expect(
          displayRect.right + MirroringCentralViewport.toolbarGap,
          lessThanOrEqualTo(rightRect.left + 1e-6),
        );
        expect(rightRect.right, lessThanOrEqualTo(1200 + 1e-6));
      },
    );
  });
}
