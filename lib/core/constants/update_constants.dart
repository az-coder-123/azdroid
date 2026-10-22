/// Constants configuring the Azdroid application update discovery and notification system.
class UpdateConstants {
  const UpdateConstants._();

  /// GitHub organization or repository owner hosting Azdroid.
  static const String repoOwner = 'az-coder-123';

  /// GitHub repository name.
  static const String repoName = 'azdroid';

  /// GitHub REST API v3 endpoint for the latest public release.
  static const String latestReleaseApiUrl =
      'https://api.github.com/repos/$repoOwner/$repoName/releases/latest';

  /// Web URL for the project's releases list.
  static const String releasesWebUrl =
      'https://github.com/$repoOwner/$repoName/releases';

  /// Web URL for the latest release.
  static const String latestReleaseWebUrl =
      'https://github.com/$repoOwner/$repoName/releases/latest';

  /// User agent header sent with requests to the GitHub API.
  static const String userAgent = 'Azdroid-App';

  /// Network timeout when checking for updates.
  static const Duration requestTimeout = Duration(seconds: 8);

  /// Minimum time between automatic background update checks to protect API rate limits.
  static const Duration autoCheckThrottle = Duration(hours: 12);
}
