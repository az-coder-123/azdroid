import 'package:desk_droid/core/platform/host_os.dart';
import 'package:desk_droid/core/platform/host_paths.dart';
import 'package:desk_droid/core/platform/host_toolchain.dart';

/// Builds a [HostToolchain] for [os] from a fake [environment], so tests do
/// not depend on the machine they run on.
HostToolchain toolchainFor(HostOs os, Map<String, String> environment) =>
    HostToolchain.forHost(
      os: os,
      paths: SystemHostPaths(
        os: os,
        environment: environment,
        systemTempPath: 'tmp',
      ),
      environment: environment,
    );
