import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:desk_droid/features/apk_installer/domain/entities/apk_info_entity.dart';
import 'package:desk_droid/features/apk_installer/domain/entities/apk_install_options.dart';
import 'package:desk_droid/features/apk_installer/domain/entities/apk_install_result.dart';
import 'package:desk_droid/features/apk_installer/domain/repositories/apk_installer_repository.dart';
import 'package:desk_droid/features/apk_installer/presentation/cubit/apk_installer_cubit.dart';
import 'package:desk_droid/features/apk_installer/presentation/cubit/apk_installer_state.dart';

class MockApkInstallerRepository extends Mock
    implements ApkInstallerRepository {}

void main() {
  late MockApkInstallerRepository mockRepo;
  const testSerial = '192.168.1.3:5555';
  const testInfo = ApkInfoEntity(
    filePath: '/path/app.apk',
    fileName: 'app.apk',
    fileSizeBytes: 2048000,
    packageName: 'com.example.app',
    appName: 'Test App',
    versionName: '1.0.0',
    versionCode: 1,
  );

  setUpAll(() {
    registerFallbackValue(const ApkInstallOptions());
  });

  setUp(() {
    mockRepo = MockApkInstallerRepository();
  });

  group('ApkInstallerCubit', () {
    test('initial state is ApkInstallerInitial', () {
      final cubit = ApkInstallerCubit(
        repository: mockRepo,
        deviceSerial: testSerial,
      );
      expect(cubit.state, isA<ApkInstallerInitial>());
      expect(cubit.state.deviceSerial, equals(testSerial));
    });

    blocTest<ApkInstallerCubit, ApkInstallerState>(
      'selectApk emits [Inspecting, Ready] upon successful inspection',
      build: () {
        when(() => mockRepo.inspectApk('/path/app.apk'))
            .thenAnswer((_) async => testInfo);
        return ApkInstallerCubit(
          repository: mockRepo,
          deviceSerial: testSerial,
        );
      },
      act: (cubit) => cubit.selectApk('/path/app.apk'),
      expect: () => [
        const ApkInstallerInspecting(
          deviceSerial: testSerial,
          filePath: '/path/app.apk',
        ),
        const ApkInstallerReady(deviceSerial: testSerial, apkInfo: testInfo),
      ],
    );

    blocTest<ApkInstallerCubit, ApkInstallerState>(
      'updateOptions updates options in Ready state',
      build: () =>
          ApkInstallerCubit(repository: mockRepo, deviceSerial: testSerial),
      seed: () =>
          const ApkInstallerReady(deviceSerial: testSerial, apkInfo: testInfo),
      act: (cubit) =>
          cubit.updateOptions(const ApkInstallOptions(allowDowngrade: true)),
      expect: () => [
        const ApkInstallerReady(
          deviceSerial: testSerial,
          apkInfo: testInfo,
          options: ApkInstallOptions(allowDowngrade: true),
        ),
      ],
    );

    blocTest<ApkInstallerCubit, ApkInstallerState>(
      'install emits [Installing, Success] on successful installation',
      build: () {
        when(() => mockRepo.installApk(testSerial, testInfo.filePath, any()))
            .thenAnswer(
              (_) async =>
                  const ApkInstallResult(success: true, rawOutput: 'Success'),
            );
        return ApkInstallerCubit(
          repository: mockRepo,
          deviceSerial: testSerial,
        );
      },
      seed: () =>
          const ApkInstallerReady(deviceSerial: testSerial, apkInfo: testInfo),
      act: (cubit) => cubit.install(),
      expect: () => [
        const ApkInstallerInstalling(
          deviceSerial: testSerial,
          apkInfo: testInfo,
          options: ApkInstallOptions(),
        ),
        const ApkInstallerSuccess(
          deviceSerial: testSerial,
          apkInfo: testInfo,
          result: ApkInstallResult(success: true, rawOutput: 'Success'),
        ),
      ],
    );

    blocTest<ApkInstallerCubit, ApkInstallerState>(
      'install emits [Installing, Failure] on installation error',
      build: () {
        when(() => mockRepo.installApk(testSerial, testInfo.filePath, any()))
            .thenAnswer(
              (_) async => const ApkInstallResult(
                success: false,
                rawOutput: 'Failure [INSTALL_FAILED_UPDATE_INCOMPATIBLE]',
                errorCode: 'INSTALL_FAILED_UPDATE_INCOMPATIBLE',
              ),
            );
        return ApkInstallerCubit(
          repository: mockRepo,
          deviceSerial: testSerial,
        );
      },
      seed: () =>
          const ApkInstallerReady(deviceSerial: testSerial, apkInfo: testInfo),
      act: (cubit) => cubit.install(),
      expect: () => [
        const ApkInstallerInstalling(
          deviceSerial: testSerial,
          apkInfo: testInfo,
          options: ApkInstallOptions(),
        ),
        const ApkInstallerFailure(
          deviceSerial: testSerial,
          apkInfo: testInfo,
          options: ApkInstallOptions(),
          result: ApkInstallResult(
            success: false,
            rawOutput: 'Failure [INSTALL_FAILED_UPDATE_INCOMPATIBLE]',
            errorCode: 'INSTALL_FAILED_UPDATE_INCOMPATIBLE',
          ),
        ),
      ],
    );

    blocTest<ApkInstallerCubit, ApkInstallerState>(
      'launchApp triggers repository and emits appLaunched=true',
      build: () {
        when(() => mockRepo.launchApp(testSerial, 'com.example.app'))
            .thenAnswer((_) async => true);
        return ApkInstallerCubit(
          repository: mockRepo,
          deviceSerial: testSerial,
        );
      },
      seed: () => const ApkInstallerSuccess(
        deviceSerial: testSerial,
        apkInfo: testInfo,
        result: ApkInstallResult(success: true, rawOutput: 'Success'),
      ),
      act: (cubit) => cubit.launchApp(),
      expect: () => [
        const ApkInstallerSuccess(
          deviceSerial: testSerial,
          apkInfo: testInfo,
          result: ApkInstallResult(success: true, rawOutput: 'Success'),
          appLaunched: true,
        ),
      ],
    );
  });
}
