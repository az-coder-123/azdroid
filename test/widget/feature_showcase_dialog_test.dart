import 'package:desk_droid/core/platform/shortcuts/shortcut_scheme.dart';
import 'package:desk_droid/features/guide/presentation/widgets/user_guide_dialog.dart';
import 'package:desk_droid/features/showcase/data/app_features_catalog.dart';
import 'package:desk_droid/features/showcase/domain/entities/app_feature_item.dart';
import 'package:desk_droid/features/showcase/presentation/widgets/feature_card.dart';
import 'package:desk_droid/features/showcase/presentation/widgets/feature_showcase_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FeatureShowcaseDialog Widget Tests', () {
    testWidgets('Renders all features on initial open with category bar', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: FeatureShowcaseDialog())),
      );
      await tester.pumpAndSettle();

      expect(find.text('DeskDroid Features Showcase'), findsOneWidget);
      expect(find.text('All Features'), findsOneWidget);
      expect(find.text('Display & Control'), findsOneWidget);
      expect(find.text('Developer Tools'), findsOneWidget);
      expect(find.text('Productivity & Media'), findsOneWidget);
      expect(find.text('Connectivity & System'), findsOneWidget);

      // Verify feature count
      final total = AppFeaturesCatalog.allFeatures.length;
      expect(find.byType(FeatureCard), findsWidgets);
      expect(find.text('Showing $total of $total features'), findsOneWidget);
    });

    testWidgets('Filtering by category updates the displayed cards', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: FeatureShowcaseDialog())),
      );
      await tester.pumpAndSettle();

      // Tap on Developer Tools category
      await tester.tap(find.text('Developer Tools'));
      await tester.pumpAndSettle();

      final devCount = AppFeaturesCatalog.allFeatures
          .where((f) => f.category == FeatureCategory.devTools)
          .length;
      final total = AppFeaturesCatalog.allFeatures.length;

      expect(find.text('Showing $devCount of $total features'), findsOneWidget);
      expect(find.text('Professional Logcat Console'), findsOneWidget);
      expect(find.text('1-Click APK Sideload & Manager'), findsOneWidget);
    });

    testWidgets('Live search filters features by keyword', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: FeatureShowcaseDialog())),
      );
      await tester.pumpAndSettle();

      final total = AppFeaturesCatalog.allFeatures.length;

      // Search for "Screen-Off"
      await tester.enterText(find.byType(TextField), 'Screen-Off');
      await tester.pumpAndSettle();

      expect(find.text('Screen-Off Mirroring'), findsOneWidget);
      expect(find.text('Showing 1 of $total features'), findsOneWidget);

      // Search for "Drag & Drop"
      await tester.enterText(find.byType(TextField), 'Drag & Drop');
      await tester.pumpAndSettle();

      expect(find.text('Direct Viewport Drag & Drop'), findsOneWidget);
      expect(find.text('Showing 1 of $total features'), findsOneWidget);

      // Search for nonexistent term
      await tester.enterText(find.byType(TextField), 'NonexistentXYZ');
      await tester.pumpAndSettle();

      expect(find.text('No matching features found'), findsOneWidget);
    });

    testWidgets('Clicking Open User Guide transitions cleanly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: FeatureShowcaseDialog())),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open User Guide'));
      await tester.pumpAndSettle();

      expect(find.byType(UserGuideDialog), findsOneWidget);
    });

    testWidgets(
      'Renders gracefully in compact/narrow mobile width without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(500, 600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: FeatureShowcaseDialog())),
        );
        await tester.pumpAndSettle();

        expect(find.text('DeskDroid Features Showcase'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Category chips display item counts in count badges', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: FeatureShowcaseDialog())),
      );
      await tester.pumpAndSettle();

      final total = AppFeaturesCatalog.allFeatures.length;
      expect(find.text('$total'), findsWidgets);

      // Verify each category count is rendered in the category bar
      for (final cat in FeatureCategory.values) {
        final count = cat == FeatureCategory.all
            ? total
            : AppFeaturesCatalog.allFeatures
                  .where((f) => f.category == cat)
                  .length;
        expect(find.text('$count'), findsWidgets);
      }
    });

    testWidgets(
      'Selecting Shortcuts category and searching Cmd+K finds Quick Text Injector',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: FeatureShowcaseDialog())),
        );
        await tester.pumpAndSettle();

        // Scroll to and tap Shortcuts & Gestures category
        await tester.ensureVisible(find.text('Shortcuts & Gestures'));
        await tester.tap(find.text('Shortcuts & Gestures'));
        await tester.pumpAndSettle();

        expect(
          find.text('Keyboard Shortcuts & Hotkeys Master'),
          findsOneWidget,
        );
        expect(
          find.text('Trackpad & Mouse Gestures Reference'),
          findsOneWidget,
        );

        // Scroll back to All Features and search for Cmd+K
        await tester.ensureVisible(find.text('All Features'));
        await tester.tap(find.text('All Features'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'Cmd+K');
        await tester.pumpAndSettle();

        expect(find.text('Quick Text Injector (Cmd+K)'), findsOneWidget);
      },
    );

    testWidgets(
      'Under PC scheme, searching Ctrl+K finds Quick Text Injector and shows adapted title',
      (tester) async {
        await tester.pumpWidget(
          RepositoryProvider<ShortcutScheme>.value(
            value: ShortcutScheme.pc,
            child: const MaterialApp(
              home: Scaffold(body: FeatureShowcaseDialog()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Under PC scheme, card title is adapted to Quick Text Injector (Ctrl+K)
        await tester.enterText(find.byType(TextField), 'Ctrl+K');
        await tester.pumpAndSettle();

        expect(find.text('Quick Text Injector (Ctrl+K)'), findsOneWidget);

        // Searching Cmd+K under PC scheme also cross-matches and finds it
        await tester.enterText(find.byType(TextField), 'Cmd+K');
        await tester.pumpAndSettle();

        expect(find.text('Quick Text Injector (Ctrl+K)'), findsOneWidget);
      },
    );
  });
}
