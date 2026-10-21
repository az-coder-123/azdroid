import 'package:desk_droid/features/showcase/data/showcase_connectivity_features.dart';
import 'package:desk_droid/features/showcase/data/showcase_devtools_features.dart';
import 'package:desk_droid/features/showcase/data/showcase_display_control_features.dart';
import 'package:desk_droid/features/showcase/data/showcase_productivity_features.dart';
import 'package:desk_droid/features/showcase/data/showcase_shortcuts_features.dart';
import 'package:desk_droid/features/showcase/domain/entities/app_feature_item.dart';

export 'package:desk_droid/features/showcase/data/showcase_connectivity_features.dart';
export 'package:desk_droid/features/showcase/data/showcase_devtools_features.dart';
export 'package:desk_droid/features/showcase/data/showcase_display_control_features.dart';
export 'package:desk_droid/features/showcase/data/showcase_productivity_features.dart';
export 'package:desk_droid/features/showcase/data/showcase_shortcuts_features.dart';

/// Curated registry of all built-in Azdroid features with user-friendly descriptions.
class AppFeaturesCatalog {
  const AppFeaturesCatalog._();

  /// Combined master catalog of all Azdroid features across all categories.
  static const List<AppFeatureItem> allFeatures = [
    ...showcaseDisplayControlFeatures,
    ...showcaseProductivityFeatures,
    ...showcaseDevToolsFeatures,
    ...showcaseConnectivityFeatures,
    ...showcaseShortcutsFeatures,
  ];
}
