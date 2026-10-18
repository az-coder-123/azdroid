import 'package:desk_droid/features/streaming/domain/entities/mirroring_preferences.dart';

/// Loads and saves [MirroringPreferences].
abstract class MirroringPreferencesRepository {
  /// Saved preferences, or the defaults when none are saved or readable.
  Future<MirroringPreferences> load();

  /// Persists [preferences]. Failures are logged, never thrown: a lost
  /// preference must not break mirroring.
  Future<void> save(MirroringPreferences preferences);
}
