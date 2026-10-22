import 'dart:convert';
import 'dart:io';

import 'package:desk_droid/core/constants/update_constants.dart';
import 'package:desk_droid/core/services/app_logger.dart';
import 'package:desk_droid/features/updater/data/models/github_release_dto.dart';

/// Contract for fetching raw release payloads from remote hosting providers.
abstract class UpdateRemoteDataSource {
  /// Fetches the latest published release DTO, or null if unreachable.
  Future<GithubReleaseDto?> fetchLatestRelease();
}

/// Signature for testing and injecting raw HTTP GET requests.
typedef HttpJsonGetter = Future<String?> Function(
  Uri uri,
  Map<String, String> headers,
);

/// Remote data source implementation communicating with GitHub REST API v3.
class GithubUpdateRemoteDataSource implements UpdateRemoteDataSource {
  GithubUpdateRemoteDataSource({String? apiEndpoint, this.httpGetter})
    : _apiEndpoint = apiEndpoint ?? UpdateConstants.latestReleaseApiUrl;

  final String _apiEndpoint;
  final HttpJsonGetter? httpGetter;

  @override
  Future<GithubReleaseDto?> fetchLatestRelease() async {
    try {
      final uri = Uri.parse(_apiEndpoint);
      final headers = {
        HttpHeaders.acceptHeader: 'application/vnd.github.v3+json',
        HttpHeaders.userAgentHeader: UpdateConstants.userAgent,
      };

      final responseBody = httpGetter != null
          ? await httpGetter!(uri, headers)
          : await _defaultHttpGet(uri, headers);

      if (responseBody == null || responseBody.trim().isEmpty) {
        return null;
      }

      final dynamic decoded = jsonDecode(responseBody);
      if (decoded is! Map<String, dynamic>) {
        AppLogger.warning(
          'GitHub update API returned non-object JSON structure.',
        );
        return null;
      }

      return GithubReleaseDto.fromJson(decoded);
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Failed to query GitHub update endpoint: $error',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<String?> _defaultHttpGet(Uri uri, Map<String, String> headers) async {
    final client = HttpClient();
    try {
      final request = await client
          .getUrl(uri)
          .timeout(UpdateConstants.requestTimeout);

      headers.forEach((key, value) {
        request.headers.set(key, value);
      });

      final response = await request.close().timeout(
        UpdateConstants.requestTimeout,
      );

      if (response.statusCode != HttpStatus.ok) {
        AppLogger.warning(
          'GitHub update check received HTTP status ${response.statusCode}',
        );
        return null;
      }

      return await response.transform(utf8.decoder).join();
    } finally {
      client.close(force: true);
    }
  }
}
