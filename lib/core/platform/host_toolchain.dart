import 'dart:io';

import 'package:desk_droid/core/platform/host_os.dart';
import 'package:desk_droid/core/platform/host_paths.dart';
import 'package:path/path.dart' as p;

/// Command names and search locations for host tools, per operating system.
///
/// This is plain data: callers never branch on the OS themselves. Adding a
/// platform means adding one factory case here. Pure Dart (no Flutter) so
/// the MCP server can use it.
class HostToolchain {
  const HostToolchain({
    required this.pathContext,
    required this.pathLookupCommand,
    required this.adbExecutable,
    required this.aaptExecutables,
    required this.androidSdkRoots,
    required this.systemAdbPaths,
    required this.bundledToolsDirectory,
    required this.arpCommand,
    required this.arpArguments,
    this.tesseractExecutable = 'tesseract',
    this.systemTesseractPaths = const [],
  });

  /// Builds the toolchain for [os], reading SDK overrides from [environment].
  factory HostToolchain.forHost({
    required HostOs os,
    required HostPaths paths,
    required Map<String, String> environment,
  }) {
    final ctx = paths.context;
    final home = paths.homeDirectory;
    final defaultSdkRoot = switch (os) {
      HostOs.macos => ctx.join(home, 'Library', 'Android', 'sdk'),
      HostOs.windows => ctx.join(
        environment['LOCALAPPDATA'] ?? ctx.join(home, 'AppData', 'Local'),
        'Android',
        'Sdk',
      ),
      HostOs.linux => ctx.join(home, 'Android', 'Sdk'),
    };
    final sdkRoots = <String>[
      for (final key in sdkEnvironmentKeys)
        if (environment[key]?.isNotEmpty ?? false) environment[key]!,
      defaultSdkRoot,
    ];

    return HostToolchain(
      pathContext: ctx,
      pathLookupCommand: os.isWindows ? 'where' : '/usr/bin/which',
      adbExecutable: os.executableName('adb'),
      aaptExecutables: [
        for (final name in _aaptBaseNames) os.executableName(name),
      ],
      androidSdkRoots: sdkRoots,
      systemAdbPaths: switch (os) {
        HostOs.macos => const ['/opt/homebrew/bin/adb', '/usr/local/bin/adb'],
        HostOs.windows => const [],
        HostOs.linux => const ['/usr/bin/adb', '/usr/local/bin/adb'],
      },
      bundledToolsDirectory: paths.executableDirectory,
      arpCommand: os.isWindows ? 'arp' : '/usr/sbin/arp',
      arpArguments: os.isWindows ? const ['-a'] : const ['-an'],
      tesseractExecutable: os.executableName('tesseract'),
      systemTesseractPaths: switch (os) {
        HostOs.macos => const [
          '/opt/homebrew/bin/tesseract',
          '/usr/local/bin/tesseract',
          '/usr/bin/tesseract',
        ],
        HostOs.windows => const [
          r'C:\Program Files\Tesseract-OCR\tesseract.exe',
          r'C:\Program Files (x86)\Tesseract-OCR\tesseract.exe',
        ],
        HostOs.linux => const [
          '/usr/bin/tesseract',
          '/usr/local/bin/tesseract',
        ],
      },
    );
  }

  /// Toolchain for the running process.
  factory HostToolchain.current() => HostToolchain.forHost(
    os: HostOs.current,
    paths: SystemHostPaths(),
    environment: Platform.environment,
  );

  /// Environment variables that may point to an Android SDK root.
  static const List<String> sdkEnvironmentKeys = [
    'ANDROID_HOME',
    'ANDROID_SDK_ROOT',
  ];

  /// Android Asset Packaging Tool names, preferred first.
  static const List<String> _aaptBaseNames = ['aapt2', 'aapt'];

  /// SDK sub-folder that holds `adb`.
  static const String platformToolsFolder = 'platform-tools';

  /// SDK sub-folder that holds versioned build-tools folders.
  static const String buildToolsFolder = 'build-tools';

  /// Path rules of the host OS, used to build the derived paths below.
  final p.Context pathContext;

  /// Command that prints the full path of an executable on `PATH`.
  final String pathLookupCommand;

  /// File name of the ADB executable.
  final String adbExecutable;

  /// File names of the aapt executables, preferred first.
  final List<String> aaptExecutables;

  /// Android SDK roots, ordered by preference.
  final List<String> androidSdkRoots;

  /// OS package-manager install locations of ADB.
  final List<String> systemAdbPaths;

  /// Folder where release builds ship their own adb (see
  /// docs/bundled-platform-tools.md).
  final String bundledToolsDirectory;

  /// Executable that prints the ARP neighbor table.
  final String arpCommand;

  /// Arguments for [arpCommand] (numeric output, no DNS lookups).
  final List<String> arpArguments;

  /// adb shipped inside the app bundle.
  String get bundledAdbPath =>
      pathContext.join(bundledToolsDirectory, adbExecutable);

  /// Absolute ADB candidates, in preference order: SDK roots, system
  /// installs, then the bundled copy. An installed adb wins so that only one
  /// adb server version runs on the machine.
  List<String> get adbSearchPaths => [
    for (final root in androidSdkRoots)
      pathContext.join(root, platformToolsFolder, adbExecutable),
    ...systemAdbPaths,
    bundledAdbPath,
  ];

  /// `build-tools` folders of every SDK root, ordered by preference.
  List<String> get buildToolsDirectories => [
    for (final root in androidSdkRoots)
      pathContext.join(root, buildToolsFolder),
  ];

  /// File name of the Tesseract executable.
  final String tesseractExecutable;

  /// OS package-manager install locations of Tesseract.
  final List<String> systemTesseractPaths;

  /// Absolute Tesseract candidates, in preference order.
  List<String> get tesseractSearchPaths => [...systemTesseractPaths];
}
