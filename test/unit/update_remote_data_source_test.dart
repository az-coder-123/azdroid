import 'package:desk_droid/features/updater/data/datasources/update_remote_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GithubUpdateRemoteDataSource', () {
    test('parses valid GitHub release JSON payload', () async {
      const mockJson = '''
      {
        "tag_name": "v1.4.1",
        "name": "v1.4.1 Release",
        "body": "Fixed critical issues",
        "html_url": "https://github.com/az-coder-123/azdroid/releases/v1.4.1",
        "draft": false,
        "prerelease": false,
        "published_at": "2026-10-22T12:00:00Z",
        "assets": [
          {
            "name": "Azdroid-v1.4.1-macOS.zip",
            "browser_download_url": "https://example.com/macos.zip",
            "size": 1024
          }
        ]
      }
      ''';

      final ds = GithubUpdateRemoteDataSource(
        apiEndpoint: 'https://example.com/api',
        httpGetter: (uri, headers) async => mockJson,
      );

      final result = await ds.fetchLatestRelease();
      expect(result, isNotNull);
      expect(result!.tagName, 'v1.4.1');
      expect(result.name, 'v1.4.1 Release');
      expect(result.assets.length, 1);
      expect(result.assets.first.name, 'Azdroid-v1.4.1-macOS.zip');
    });

    test('returns null when http getter returns null or empty', () async {
      final ds = GithubUpdateRemoteDataSource(
        apiEndpoint: 'https://example.com/api',
        httpGetter: (uri, headers) async => null,
      );

      final result = await ds.fetchLatestRelease();
      expect(result, isNull);
    });

    test('returns null gracefully on non-json or broken response', () async {
      final ds = GithubUpdateRemoteDataSource(
        apiEndpoint: 'https://example.com/api',
        httpGetter: (uri, headers) async => '<html>502 Bad Gateway</html>',
      );

      final result = await ds.fetchLatestRelease();
      expect(result, isNull);
    });
  });
}
