import 'package:desk_droid/core/theme/app_theme.dart';
import 'package:desk_droid/features/showcase/data/app_features_catalog.dart';
import 'package:desk_droid/features/showcase/domain/entities/app_feature_item.dart';
import 'package:desk_droid/features/showcase/presentation/widgets/feature_card.dart';
import 'package:flutter/material.dart';
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
}
