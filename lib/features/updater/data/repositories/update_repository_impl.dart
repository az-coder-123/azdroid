import 'package:desk_droid/core/constants/update_constants.dart';
import 'package:desk_droid/core/platform/host_os.dart';
import 'package:desk_droid/features/updater/data/datasources/update_remote_data_source.dart';
import 'package:desk_droid/features/updater/data/models/github_release_dto.dart';
import 'package:desk_droid/features/updater/domain/entities/app_update_info.dart';
import 'package:desk_droid/features/updater/domain/entities/semantic_version.dart';
import 'package:desk_droid/features/updater/domain/repositories/update_repository.dart';

/// Implementation of [UpdateRepository] evaluating GitHub releases against host OS requirements.
class UpdateRepositoryImpl implements UpdateRepository {
  UpdateRepositoryImpl({
    required this.remoteDataSource,
    required this.hostOs,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final UpdateRemoteDataSource remoteDataSource;
  final HostOs hostOs;
  final DateTime Function() _clock;

  DateTime? _lastCheckTime;
  AppUpdateInfo? _cachedUpdateInfo;

  @override
  Future<AppUpdateInfo?> checkForUpdate({
    required String currentVersionRaw,
    bool force = false,
  }) async {
    final now = _clock();

    // Respect throttle interval during automatic background scans
    if (!force && _lastCheckTime != null) {
      final elapsed = now.difference(_lastCheckTime!);
      if (elapsed < UpdateConstants.autoCheckThrottle) {
        return _cachedUpdateInfo;
      }
    }

    final currentVersion = SemanticVersion.tryParse(currentVersionRaw);
    if (currentVersion == null) {
      return null;
    }

    final releaseDto = await remoteDataSource.fetchLatestRelease();
    _lastCheckTime = now;

    if (releaseDto == null || releaseDto.draft) {
      return _cachedUpdateInfo;
    }

    final latestVersion = SemanticVersion.tryParse(releaseDto.tagName);
    if (latestVersion == null || !latestVersion.isGreaterThan(currentVersion)) {
      _cachedUpdateInfo = null;
      return null;
    }

    final matchedAsset = _findMatchingAsset(releaseDto.assets);

    final info = AppUpdateInfo(
      currentVersion: currentVersion,
      latestVersion: latestVersion,
      tagName: releaseDto.tagName,
      releaseName: releaseDto.name.isNotEmpty
          ? releaseDto.name
          : 'Azdroid ${releaseDto.tagName}',
      releaseNotes: releaseDto.body,
      htmlUrl: releaseDto.htmlUrl.isNotEmpty
          ? releaseDto.htmlUrl
          : UpdateConstants.latestReleaseWebUrl,
      publishedAt: releaseDto.publishedAt,
      downloadUrl: matchedAsset?.browserDownloadUrl,
      assetName: matchedAsset?.name,
      assetSizeBytes: matchedAsset?.sizeBytes,
    );

    _cachedUpdateInfo = info;
    return info;
  }

  GithubReleaseAssetDto? _findMatchingAsset(
    List<GithubReleaseAssetDto> assets,
  ) {
    if (assets.isEmpty) return null;

    final keyword = hostOs.isWindows ? 'windows' : 'macos';

    for (final asset in assets) {
      final lowerName = asset.name.toLowerCase();
      if (lowerName.contains(keyword) && lowerName.endsWith('.zip')) {
        return asset;
      }
    }

    // Fallback: any zip archive
    for (final asset in assets) {
      if (asset.name.toLowerCase().endsWith('.zip')) {
        return asset;
      }
    }

    return null;
  }
}
