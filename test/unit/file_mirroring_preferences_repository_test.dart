import 'dart:io';

import 'package:desk_droid/core/platform/host_os.dart';
import 'package:desk_droid/core/platform/host_paths.dart';
import 'package:desk_droid/features/streaming/data/repositories/file_mirroring_preferences_repository.dart';
import 'package:desk_droid/features/streaming/domain/entities/mirroring_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory root;
  late HostPaths paths;
  late FileMirroringPreferencesRepository repository;

  setUp(() {
    root = Directory.systemTemp.createTempSync('mirroring_prefs_');
    paths = SystemHostPaths(
      os: HostOs.current,
      environment: {
        'HOME': root.path,
        'USERPROFILE': root.path,
        'APPDATA': root.path,
        'XDG_DATA_HOME': root.path,
      },
      systemTempPath: root.path,
    );
    repository = FileMirroringPreferencesRepository(hostPaths: paths);
  });
  tearDown(() => root.deleteSync(recursive: true));

  File prefsFile() => File(
    paths.context.join(
      paths.appDataDirectory,
      FileMirroringPreferencesRepository.fileName,
    ),
  );

  test('returns the defaults when nothing is saved', () async {
    expect(await repository.load(), const MirroringPreferences());
    expect(const MirroringPreferences().stayAwake, isTrue);
  });

  test('saves and loads stay awake, creating the folder', () async {
    await repository.save(const MirroringPreferences(stayAwake: false));

    expect(prefsFile().existsSync(), isTrue);
    final reloaded = FileMirroringPreferencesRepository(hostPaths: paths);
    expect(await reloaded.load(), const MirroringPreferences(stayAwake: false));
  });

  test('falls back to the defaults for a corrupt file', () async {
    prefsFile()
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('{not json');

    expect(await repository.load(), const MirroringPreferences());
  });

  test('falls back to the default for a value of the wrong type', () async {
    prefsFile()
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('{"stayAwake": "no"}');

    expect(await repository.load(), const MirroringPreferences());
  });
}
