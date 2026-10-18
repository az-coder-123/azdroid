import 'package:desk_droid/core/platform/shortcuts/shortcut_scheme.dart';
import 'package:desk_droid/core/theme/app_theme.dart';
import 'package:desk_droid/features/showcase/data/app_features_catalog.dart';
import 'package:desk_droid/features/showcase/domain/entities/app_feature_item.dart';
import 'package:desk_droid/features/showcase/presentation/widgets/feature_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpCard(
    WidgetTester tester,
    AppFeatureItem item,
    double width,
  ) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: SingleChildScrollView(child: FeatureCard(feature: item)),
          ),
        ),
      ),
    ),
  );

  final base = AppFeaturesCatalog.allFeatures.first;
  final longBadge = AppFeatureItem(
    id: 'long',
    title: 'A Feature With a Fairly Long Title',
    subtitle: base.subtitle,
    category: base.category,
    icon: base.icon,
    badgeText: 'A very long badge text that cannot fit next to the title',
    badgeColor: base.badgeColor,
    highlights: base.highlights,
    proTip: base.proTip,
    docFileName: base.docFileName,
  );

  for (final width in [260.0, 360.0, 520.0]) {
    testWidgets('a long badge does not overflow at width $width', (
      tester,
    ) async {
      await pumpCard(tester, longBadge, width);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('every catalog card fits a narrow width', (tester) async {
    for (final item in AppFeaturesCatalog.allFeatures) {
      await pumpCard(tester, item, 300);
      expect(tester.takeException(), isNull, reason: item.id);
    }
  });

  testWidgets('adapts shortcuts and symbols according to host OS scheme', (
    tester,
  ) async {
    final textInjectFeature = AppFeaturesCatalog.allFeatures.firstWhere(
      (f) => f.id == 'text_injector',
    );

    // On macOS
    await tester.pumpWidget(
      RepositoryProvider<ShortcutScheme>.value(
        value: ShortcutScheme.mac,
        child: MaterialApp(
          home: Scaffold(body: FeatureCard(feature: textInjectFeature)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Quick Text Injector (Cmd+K)'), findsOneWidget);
    expect(find.text('⌘K • Text Injector'), findsOneWidget);

    // On Windows / PC
    await tester.pumpWidget(
      RepositoryProvider<ShortcutScheme>.value(
        value: ShortcutScheme.pc,
        child: MaterialApp(
          home: Scaffold(body: FeatureCard(feature: textInjectFeature)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Quick Text Injector (Ctrl+K)'), findsOneWidget);
    expect(find.text('Ctrl+K • Text Injector'), findsOneWidget);
  });

  testWidgets('renders adapted hotkeys master on macOS vs Windows', (
    tester,
  ) async {
    final shortcutsFeature = AppFeaturesCatalog.allFeatures.firstWhere(
      (f) => f.id == 'shortcuts_master',
    );

    // On macOS
    await tester.pumpWidget(
      RepositoryProvider<ShortcutScheme>.value(
        value: ShortcutScheme.mac,
        child: MaterialApp(
          home: Scaffold(body: FeatureCard(feature: shortcutsFeature)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('⌘ Keys • Hotkeys'), findsOneWidget);

    // On Windows
    await tester.pumpWidget(
      RepositoryProvider<ShortcutScheme>.value(
        value: ShortcutScheme.pc,
        child: MaterialApp(
          home: Scaffold(body: FeatureCard(feature: shortcutsFeature)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ctrl Keys • Hotkeys'), findsOneWidget);
  });
}
