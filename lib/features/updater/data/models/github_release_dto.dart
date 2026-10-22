/// Data Transfer Object representing an individual release binary asset from GitHub.
class GithubReleaseAssetDto {
  const GithubReleaseAssetDto({
    required this.name,
    required this.browserDownloadUrl,
    this.sizeBytes,
    this.contentType,
  });

  factory GithubReleaseAssetDto.fromJson(Map<String, dynamic> json) {
    return GithubReleaseAssetDto(
      name: (json['name'] as String?)?.trim() ?? '',
      browserDownloadUrl:
          (json['browser_download_url'] as String?)?.trim() ?? '',
      sizeBytes: json['size'] as int?,
      contentType: json['content_type'] as String?,
    );
  }

  final String name;
  final String browserDownloadUrl;
  final int? sizeBytes;
  final String? contentType;
}

/// Data Transfer Object parsing the GitHub REST API v3 release response.
class GithubReleaseDto {
  const GithubReleaseDto({
    required this.tagName,
    required this.name,
    required this.body,
    required this.htmlUrl,
    required this.draft,
    required this.prerelease,
    this.publishedAt,
    this.assets = const [],
  });

  factory GithubReleaseDto.fromJson(Map<String, dynamic> json) {
    final rawAssets = json['assets'];
    final assetList = <GithubReleaseAssetDto>[];
    if (rawAssets is List) {
      for (final item in rawAssets) {
        if (item is Map<String, dynamic>) {
          assetList.add(GithubReleaseAssetDto.fromJson(item));
        }
      }
    }

    DateTime? publishedDate;
    final publishedStr = json['published_at'] as String?;
    if (publishedStr != null) {
      publishedDate = DateTime.tryParse(publishedStr);
    }

    return GithubReleaseDto(
      tagName: (json['tag_name'] as String?)?.trim() ?? '',
      name: (json['name'] as String?)?.trim() ?? '',
      body: (json['body'] as String?)?.trim() ?? '',
      htmlUrl: (json['html_url'] as String?)?.trim() ?? '',
      draft: json['draft'] as bool? ?? false,
      prerelease: json['prerelease'] as bool? ?? false,
      publishedAt: publishedDate,
      assets: assetList,
    );
  }

  final String tagName;
  final String name;
  final String body;
  final String htmlUrl;
  final bool draft;
  final bool prerelease;
  final DateTime? publishedAt;
  final List<GithubReleaseAssetDto> assets;
}
