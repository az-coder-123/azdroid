import 'package:desk_droid/core/platform/host_os.dart';

/// Pinned Android SDK Platform-Tools release bundled with Azdroid.
///
/// To upgrade: read the version, size, and SHA-1 for `platform-tools` from
/// https://dl.google.com/android/repository/repository2-3.xml, download each
/// archive, confirm the SHA-1 matches, then record its SHA-256 here.
/// See docs/bundled-platform-tools.md.
const String platformToolsVersion = '37.0.1';

/// Base URL of Google's Android SDK repository.
const String _repositoryBaseUrl = 'https://dl.google.com/android/repository';

/// One downloadable platform-tools archive and the files Azdroid ships.
class PlatformToolsPackage {
  const PlatformToolsPackage({
    required this.archiveName,
    required this.sizeBytes,
    required this.sha1,
    required this.sha256,
    required this.files,
    required this.executables,
  });

  final String archiveName;
  final int sizeBytes;

  /// Checksum published by Google in repository2-3.xml (provenance).
  final String sha1;

  /// Checksum Azdroid verifies before extracting (integrity).
  final String sha256;

  /// Archive entry path -> file name in the output folder.
  final Map<String, String> files;

  /// Output names that must be executable on POSIX hosts.
  final Set<String> executables;

  String get url => '$_repositoryBaseUrl/$archiveName';
}

const String _notice = 'platform-tools/NOTICE.txt';
const String _sourceProperties = 'platform-tools/source.properties';

/// File name of the bundled license notice, next to the adb binary.
const String noticeFileName = 'platform-tools-NOTICE.txt';

/// File name recording the bundled version, next to the adb binary.
const String sourcePropertiesFileName = 'platform-tools-source.properties';

/// Packages per host OS. Only adb and the files it needs are extracted.
const Map<HostOs, PlatformToolsPackage> platformToolsPackages = {
  HostOs.macos: PlatformToolsPackage(
    archiveName: 'platform-tools_r37.0.1-darwin.zip',
    sizeBytes: 16110554,
    sha1: '6ae73f4de6452dc57e62ec02b68eed92a4c21661',
    sha256: 'ee39ad5967e95c2a07f04dbcbde96b1a0c916ba376096db5d2f498b7727a5d1d',
    files: {
      // Universal (x86_64 + arm64), signed by Google; only system frameworks.
      'platform-tools/adb': 'adb',
      _notice: noticeFileName,
      _sourceProperties: sourcePropertiesFileName,
    },
    executables: {'adb'},
  ),
  HostOs.windows: PlatformToolsPackage(
    archiveName: 'platform-tools_r37.0.1-win.zip',
    sizeBytes: 8044989,
    sha1: 'e03e78b1d80b396f1c3358e31251cb31740e1110',
    sha256: '45f4d63113e895ebde0c90f194099a4676b6ac653bd28d54314a9e022bbc1a99',
    files: {
      // adb.exe imports AdbWinApi.dll, which loads AdbWinUsbApi.dll.
      'platform-tools/adb.exe': 'adb.exe',
      'platform-tools/AdbWinApi.dll': 'AdbWinApi.dll',
      'platform-tools/AdbWinUsbApi.dll': 'AdbWinUsbApi.dll',
      _notice: noticeFileName,
      _sourceProperties: sourcePropertiesFileName,
    },
    executables: {},
  ),
};

/// Folder (relative to the project root) holding extracted tools for [os].
String vendorDirectory(HostOs os) => 'vendor/platform-tools/${os.name}';

/// Stamp file written after a successful extraction.
const String stampFileName = '.version';
