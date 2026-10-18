import 'dart:convert';
import 'dart:io';

import 'package:desk_droid/core/platform/host_paths.dart';
import 'package:desk_droid/core/services/app_logger.dart';
import 'package:desk_droid/features/streaming/domain/entities/mirroring_preferences.dart';
import 'package:desk_droid/features/streaming/domain/repositories/mirroring_preferences_repository.dart';

/// Stores [MirroringPreferences] as JSON in the app data folder.
class FileMirroringPreferencesRepository
    implements MirroringPreferencesRepository {
  FileMirroringPreferencesRepository({required HostPaths hostPaths})
    : _paths = hostPaths;

  /// File name inside the app data folder.
  static const String fileName = 'mirroring_preferences.json';
  static const String _stayAwakeKey = 'stayAwake';

  final HostPaths _paths;

  File get _file =>
      File(_paths.context.join(_paths.appDataDirectory, fileName));

  @override
  Future<MirroringPreferences> load() async {
    try {
      final file = _file;
      if (!await file.exists()) return const MirroringPreferences();
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) {
        return const MirroringPreferences();
      }
      final stayAwake = decoded[_stayAwakeKey];
      return MirroringPreferences(
        stayAwake: stayAwake is bool
            ? stayAwake
            : MirroringPreferences.defaultStayAwake,
      );
    } on Exception catch (e, stack) {
      AppLogger.warning(
        'Failed to read mirroring preferences; using defaults',
        error: e,
        stackTrace: stack,
      );
      return const MirroringPreferences();
    }
  }

  @override
  Future<void> save(MirroringPreferences preferences) async {
    try {
      final file = _file;
      await file.parent.create(recursive: true);
      await file.writeAsString(
        jsonEncode({_stayAwakeKey: preferences.stayAwake}),
      );
    } on Exception catch (e, stack) {
      AppLogger.warning(
        'Failed to save mirroring preferences',
        error: e,
        stackTrace: stack,
      );
    }
  }
}
