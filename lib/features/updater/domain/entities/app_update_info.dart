import 'package:desk_droid/features/updater/domain/entities/semantic_version.dart';
import 'package:equatable/equatable.dart';

/// Immutable domain entity detailing an available application update.
class AppUpdateInfo extends Equatable {
  const AppUpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.tagName,
    required this.releaseName,
    required this.releaseNotes,
    required this.htmlUrl,
    this.publishedAt,
    this.downloadUrl,
    this.assetName,
    this.assetSizeBytes,
  });

  /// The version currently executing on this machine.
  final SemanticVersion currentVersion;

  /// The newly discovered version available on GitHub.
  final SemanticVersion latestVersion;

  /// Git tag of the release (e.g. `v1.4.1`).
  final String tagName;

  /// Human-readable title of the release from GitHub.
  final String releaseName;

  /// Markdown release notes describing new features and bug fixes.
  final String releaseNotes;

  /// Direct web URL to the GitHub release page.
  final String htmlUrl;

  /// Timestamp when the release was published.
  final DateTime? publishedAt;

  /// Direct download URL for the target platform ZIP package, if available.
  final String? downloadUrl;

  /// File name of the matched binary asset (e.g. `Azdroid-v1.4.1-macOS.zip`).
  final String? assetName;

  /// Size of the binary asset in bytes.
  final int? assetSizeBytes;

  /// Returns true if a direct package download link is known for this host OS.
  bool get hasDirectDownload => downloadUrl != null && downloadUrl!.isNotEmpty;

  /// Returns formatted size string (e.g. `42.5 MB`).
  String? get formattedAssetSize {
    final bytes = assetSizeBytes;
    if (bytes == null || bytes <= 0) return null;
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  @override
  List<Object?> get props => [
    currentVersion,
    latestVersion,
    tagName,
    releaseName,
    releaseNotes,
    htmlUrl,
    publishedAt,
    downloadUrl,
    assetName,
    assetSizeBytes,
  ];
}
