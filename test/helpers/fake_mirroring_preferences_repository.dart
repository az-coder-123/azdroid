import 'package:desk_droid/features/streaming/domain/entities/mirroring_preferences.dart';
import 'package:desk_droid/features/streaming/domain/repositories/mirroring_preferences_repository.dart';

/// In-memory [MirroringPreferencesRepository] that records saves.
class FakeMirroringPreferencesRepository
    implements MirroringPreferencesRepository {
  FakeMirroringPreferencesRepository([
    this.stored = const MirroringPreferences(),
  ]);

  MirroringPreferences stored;
  final List<MirroringPreferences> saved = [];

  @override
  Future<MirroringPreferences> load() async => stored;

  @override
  Future<void> save(MirroringPreferences preferences) async {
    stored = preferences;
    saved.add(preferences);
  }
}
