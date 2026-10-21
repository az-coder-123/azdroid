import 'package:desk_droid/core/platform/host_os.dart';
import 'package:desk_droid/core/platform/host_paths.dart';
import 'package:desk_droid/features/logging/data/services/log_file_path_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fixedClock = DateTime(2026, 10, 17, 9, 5, 7);

  LogFilePathBuilder builderFor(HostOs os, Map<String, String> env) =>
      LogFilePathBuilder(
        hostPaths: SystemHostPaths(
          os: os,
          environment: env,
          systemTempPath: 'tmp',
        ),
        clock: () => fixedClock,
      );

  group('LogFilePathBuilder on macOS', () {
    final builder = builderFor(HostOs.macos, {'HOME': '/Users/dev'});

    test('recording path uses Downloads/azdroid_logs and a safe serial', () {
      expect(
        builder.recordingPath('192.168.43.148:5555'),
        '/Users/dev/Downloads/azdroid_logs/'
        'logcat_192_168_43_148_5555_20261017_090507.log',
      );
    });

    test('snapshot path honors a custom directory', () {
      expect(
        builder.snapshotPath('emulator-5554', directory: '/tmp/out'),
        '/tmp/out/logcat_snapshot_emulator-5554_20261017_090507.log',
      );
    });
  });

  test('Windows paths use backslashes under USERPROFILE', () {
    final builder = builderFor(HostOs.windows, {
      'USERPROFILE': r'C:\Users\dev',
    });

    expect(
      builder.recordingPath('R58M123'),
      r'C:\Users\dev\Downloads\azdroid_logs\logcat_R58M123_20261017_090507.log',
    );
  });
}
