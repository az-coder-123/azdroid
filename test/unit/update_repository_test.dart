import 'package:desk_droid/core/platform/host_os.dart';
import 'package:desk_droid/features/updater/data/datasources/update_remote_data_source.dart';
import 'package:desk_droid/features/updater/data/models/github_release_dto.dart';
import 'package:desk_droid/features/updater/data/repositories/update_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockUpdateRemoteDataSource extends Mock
    implements UpdateRemoteDataSource {}

void main() {
  late MockUpdateRemoteDataSource mockRemote;

  setUp(() {
    mockRemote = MockUpdateRemoteDataSource();
  });

  const sampleReleaseDto = GithubReleaseDto(
    tagName: 'v1.4.1',
    name: 'Azdroid v1.4.1 — Maintenance Release',
    body: '### Bug Fixes\n* Fixed Wi-Fi timeout',
    htmlUrl: 'https://github.com/az-coder-123/azdroid/releases/tag/v1.4.1',
    draft: false,
    prerelease: false,
    assets: [
      GithubReleaseAssetDto(
        name: 'Azdroid-v1.4.1-macOS.zip',
        browserDownloadUrl: 'https://example.com/Azdroid-v1.4.1-macOS.zip',
        sizeBytes: 42000000,
      ),
      GithubReleaseAssetDto(
        name: 'Azdroid-v1.4.1-Windows.zip',
        browserDownloadUrl: 'https://example.com/Azdroid-v1.4.1-Windows.zip',
        sizeBytes: 45000000,
      ),
    ],
  );

  group('UpdateRepositoryImpl', () {
    test('discovers newer release and matches macOS asset', () async {
      when(() => mockRemote.fetchLatestRelease())
          .thenAnswer((_) async => sampleReleaseDto);

      final repo = UpdateRepositoryImpl(
        remoteDataSource: mockRemote,
        hostOs: HostOs.macos,
      );

      final result = await repo.checkForUpdate(currentVersionRaw: '1.4.0');

      expect(result, isNotNull);
      expect(result!.latestVersion.toString(), 'v1.4.1');
      expect(result.currentVersion.toString(), 'v1.4.0');
      expect(result.assetName, 'Azdroid-v1.4.1-macOS.zip');
      expect(
        result.downloadUrl,
        'https://example.com/Azdroid-v1.4.1-macOS.zip',
      );
      verify(() => mockRemote.fetchLatestRelease()).called(1);
    });

    test('discovers newer release and matches Windows asset', () async {
      when(() => mockRemote.fetchLatestRelease())
          .thenAnswer((_) async => sampleReleaseDto);

      final repo = UpdateRepositoryImpl(
        remoteDataSource: mockRemote,
        hostOs: HostOs.windows,
      );

      final result = await repo.checkForUpdate(currentVersionRaw: '1.4.0');

      expect(result, isNotNull);
      expect(result!.assetName, 'Azdroid-v1.4.1-Windows.zip');
      expect(
        result.downloadUrl,
        'https://example.com/Azdroid-v1.4.1-Windows.zip',
      );
    });

    test('returns null when current version is equal or newer', () async {
      when(() => mockRemote.fetchLatestRelease())
          .thenAnswer((_) async => sampleReleaseDto);

      final repo = UpdateRepositoryImpl(
        remoteDataSource: mockRemote,
        hostOs: HostOs.macos,
      );

      final resultSame = await repo.checkForUpdate(currentVersionRaw: '1.4.1');
      expect(resultSame, isNull);

      final resultNewer = await repo.checkForUpdate(currentVersionRaw: '1.5.0');
      expect(resultNewer, isNull);
    });

    test('throttles rapid background calls within 12 hours', () async {
      when(() => mockRemote.fetchLatestRelease())
          .thenAnswer((_) async => sampleReleaseDto);

      var fakeTime = DateTime(2026, 10, 22, 10, 0);

      final repo = UpdateRepositoryImpl(
        remoteDataSource: mockRemote,
        hostOs: HostOs.macos,
        clock: () => fakeTime,
      );

      // Call 1
      final res1 = await repo.checkForUpdate(currentVersionRaw: '1.4.0');
      expect(res1, isNotNull);
      verify(() => mockRemote.fetchLatestRelease()).called(1);

      // Call 2: only 1 hour later without force
      fakeTime = fakeTime.add(const Duration(hours: 1));
      final res2 = await repo.checkForUpdate(currentVersionRaw: '1.4.0');
      expect(res2, equals(res1));
      // Should NOT call remote again
      verifyNever(() => mockRemote.fetchLatestRelease());

      // Call 3: with force: true, should bypass throttle
      final res3 = await repo.checkForUpdate(
        currentVersionRaw: '1.4.0',
        force: true,
      );
      expect(res3, equals(res1));
      verify(() => mockRemote.fetchLatestRelease()).called(1);
    });
  });
}
