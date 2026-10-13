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
      expect(find.text('Lưu file'), findsOneWidget);
      expect(find.text('Cả hai'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // Tap Clipboard
      await tester.tap(find.text('Clipboard'));
      await tester.pump();
      expect(selectedDestination, ScreenshotDestination.clipboard);

      // Tap Lưu file
      await tester.tap(find.text('Lưu file'));
      await tester.pump();
      expect(selectedDestination, ScreenshotDestination.file);

      // Tap Cả hai
      await tester.tap(find.text('Cả hai'));
      await tester.pump();
      expect(selectedDestination, ScreenshotDestination.both);

      // Tap Cancel
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      expect(cancelCalled, isTrue);
    });
  });
}
