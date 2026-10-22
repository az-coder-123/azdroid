import 'package:bloc_test/bloc_test.dart';
import 'package:desk_droid/core/constants/update_constants.dart';
import 'package:desk_droid/core/platform/file_launcher/host_file_launcher.dart';
import 'package:desk_droid/features/updater/domain/entities/app_update_info.dart';
import 'package:desk_droid/features/updater/domain/entities/semantic_version.dart';
import 'package:desk_droid/features/updater/domain/repositories/update_repository.dart';
import 'package:desk_droid/features/updater/presentation/cubit/updater_cubit.dart';
import 'package:desk_droid/features/updater/presentation/cubit/updater_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockUpdateRepository extends Mock implements UpdateRepository {}

class MockHostFileLauncher extends Mock implements HostFileLauncher {}

void main() {
  late MockUpdateRepository mockRepo;
  late MockHostFileLauncher mockLauncher;

  const sampleInfo = AppUpdateInfo(
    currentVersion: SemanticVersion(1, 4, 0),
    latestVersion: SemanticVersion(1, 4, 1),
    tagName: 'v1.4.1',
    releaseName: 'Azdroid 1.4.1',
    releaseNotes: 'Performance improvements',
    htmlUrl: 'https://github.com/az-coder-123/azdroid/releases/tag/v1.4.1',
    downloadUrl: 'https://example.com/download.zip',
  );

  setUp(() {
    mockRepo = MockUpdateRepository();
    mockLauncher = MockHostFileLauncher();
  });

  group('UpdaterCubit', () {
    test('initial state is UpdaterInitial', () {
      final cubit = UpdaterCubit(
        updateRepository: mockRepo,
        fileLauncher: mockLauncher,
        currentVersion: '1.4.0',
      );
      expect(cubit.state, const UpdaterInitial());
    });

    blocTest<UpdaterCubit, UpdaterState>(
      'emits [UpdaterChecking, UpdaterAvailable] when update is found',
      setUp: () {
        when(
          () => mockRepo.checkForUpdate(
            currentVersionRaw: any(named: 'currentVersionRaw'),
            force: any(named: 'force'),
          ),
        ).thenAnswer((_) async => sampleInfo);
      },
      build: () => UpdaterCubit(
        updateRepository: mockRepo,
        fileLauncher: mockLauncher,
        currentVersion: '1.4.0',
      ),
      act: (cubit) => cubit.checkForUpdates(),
      expect: () => [
        const UpdaterChecking(),
        const UpdaterAvailable(updateInfo: sampleInfo),
      ],
    );

    blocTest<UpdaterCubit, UpdaterState>(
      'emits [UpdaterChecking, UpdaterUpToDate] when no update is found',
      setUp: () {
        when(
          () => mockRepo.checkForUpdate(
            currentVersionRaw: any(named: 'currentVersionRaw'),
            force: any(named: 'force'),
          ),
        ).thenAnswer((_) async => null);
      },
      build: () => UpdaterCubit(
        updateRepository: mockRepo,
        fileLauncher: mockLauncher,
        currentVersion: '1.4.0',
      ),
      act: (cubit) => cubit.checkForUpdates(),
      expect: () => [
        const UpdaterChecking(),
        const UpdaterUpToDate(currentVersion: '1.4.0'),
      ],
    );

    blocTest<UpdaterCubit, UpdaterState>(
      'emits [UpdaterChecking, UpdaterFailure] when repository throws error',
      setUp: () {
        when(
          () => mockRepo.checkForUpdate(
            currentVersionRaw: any(named: 'currentVersionRaw'),
            force: any(named: 'force'),
          ),
        ).thenThrow(Exception('Network error'));
      },
      build: () => UpdaterCubit(
        updateRepository: mockRepo,
        fileLauncher: mockLauncher,
        currentVersion: '1.4.0',
      ),
      act: (cubit) => cubit.checkForUpdates(),
      expect: () => [
        const UpdaterChecking(),
        const UpdaterFailure(message: 'Unable to check for updates.'),
      ],
    );

    blocTest<UpdaterCubit, UpdaterState>(
      'dismissBanner sets isBannerDismissed to true on UpdaterAvailable',
      seed: () => const UpdaterAvailable(updateInfo: sampleInfo),
      build: () => UpdaterCubit(
        updateRepository: mockRepo,
        fileLauncher: mockLauncher,
        currentVersion: '1.4.0',
      ),
      act: (cubit) => cubit.dismissBanner(),
      expect: () => [
        const UpdaterAvailable(updateInfo: sampleInfo, isBannerDismissed: true),
      ],
    );

    test('launchDownload opens downloadUrl via fileLauncher', () async {
      when(() => mockLauncher.open(any())).thenAnswer((_) async => true);

      final cubit = UpdaterCubit(
        updateRepository: mockRepo,
        fileLauncher: mockLauncher,
        currentVersion: '1.4.0',
      );

      final ok = await cubit.launchDownload(sampleInfo);
      expect(ok, isTrue);
      verify(() => mockLauncher.open('https://example.com/download.zip'))
          .called(1);
    });

    test('launchReleasesPage opens releasesWebUrl via fileLauncher', () async {
      when(() => mockLauncher.open(any())).thenAnswer((_) async => true);

      final cubit = UpdaterCubit(
        updateRepository: mockRepo,
        fileLauncher: mockLauncher,
        currentVersion: '1.4.0',
      );

      final ok = await cubit.launchReleasesPage();
      expect(ok, isTrue);
      verify(() => mockLauncher.open(UpdateConstants.releasesWebUrl)).called(1);
    });
  });
}
