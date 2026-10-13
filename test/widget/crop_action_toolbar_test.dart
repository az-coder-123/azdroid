import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wifi_desk/features/productivity/domain/entities/screenshot_destination.dart';
import 'package:wifi_desk/features/productivity/presentation/widgets/crop_action_toolbar.dart';

void main() {
  group('CropActionToolbar', () {
    testWidgets('renders all destination buttons and triggers callbacks', (
      tester,
    ) async {
      ScreenshotDestination? selectedDestination;
      var cancelCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CropActionToolbar(
                onSelect: (dest) => selectedDestination = dest,
                onCancel: () => cancelCalled = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Clipboard'), findsOneWidget);
      expect(find.text('Save File'), findsOneWidget);
      expect(find.text('Both'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // Tap Clipboard
      await tester.tap(find.text('Clipboard'));
      await tester.pump();
      expect(selectedDestination, ScreenshotDestination.clipboard);

      // Tap Save File
      await tester.tap(find.text('Save File'));
      await tester.pump();
      expect(selectedDestination, ScreenshotDestination.file);

      // Tap Both
      await tester.tap(find.text('Both'));
      await tester.pump();
      expect(selectedDestination, ScreenshotDestination.both);

      // Tap Cancel
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      expect(cancelCalled, isTrue);
    });
  });
}
