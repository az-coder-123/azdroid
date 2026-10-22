import 'package:desk_droid/features/updater/domain/entities/app_update_info.dart';

/// Contract for checking, caching, and discovering newer application releases.
abstract class UpdateRepository {
  /// Checks whether a newer release is published on the distribution repository.
  ///
  /// Compares [currentVersionRaw] (e.g. `1.4.0`) against the newest release tag.
  /// If [force] is true, bypasses any throttle duration and queries remote servers.
  /// Returns [AppUpdateInfo] if an update is found, or null if the app is up to date
  /// or when network conditions prevent validation.
  Future<AppUpdateInfo?> checkForUpdate({
    required String currentVersionRaw,
    bool force = false,
  });
}
