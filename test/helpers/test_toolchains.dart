import 'package:desk_droid/core/platform/host_os.dart';
import 'package:desk_droid/core/platform/host_paths.dart';
import 'package:desk_droid/core/platform/host_toolchain.dart';

/// Builds a [HostToolchain] for [os] from a fake [environment], so tests do
/// not depend on the machine they run on.
HostToolchain toolchainFor(
  HostOs os,
  Map<String, String> environment, {
  String? executablePath,
}) => HostToolchain.forHost(
  os: os,
  paths: SystemHostPaths(
    os: os,
    environment: environment,
    systemTempPath: 'tmp',
    executablePath: executablePath ?? testExecutablePaths[os],
  ),
  environment: environment,
);

/// Installed app executables used by tests, so bundled-tool paths are fixed.
const Map<HostOs, String> testExecutablePaths = {
  HostOs.macos: '/Applications/Azdroid.app/Contents/MacOS/Azdroid',
  HostOs.windows: r'C:\Program Files\Azdroid\desk_droid.exe',
  HostOs.linux: '/opt/azdroid/desk_droid',
};
