import 'package:desk_droid/core/extensions/line_split_extension.dart';
import 'package:desk_droid/core/platform/host_os.dart';

/// A command line: executable plus its leading arguments.
typedef HostCommand = ({String executable, List<String> arguments});

/// Host commands that inspect executables and running processes, per
/// operating system. Plain data, so callers never branch on the OS.
///
/// Pure Dart (no Flutter).
class HostProcessTools {
  const HostProcessTools({
    required this.os,
    required this.binaryArchitectures,
    required this.appleSiliconCheck,
  });

  factory HostProcessTools.forHost(HostOs os) => HostProcessTools(
    os: os,
    binaryArchitectures: os == HostOs.macos
        ? (executable: '/usr/bin/lipo', arguments: const ['-archs'])
        : null,
    appleSiliconCheck: os == HostOs.macos
        ? (
            executable: '/usr/sbin/sysctl',
            arguments: const ['-n', 'hw.optional.arm64'],
          )
        : null,
  );

  final HostOs os;

  /// Prints the CPU architectures of the executable appended as the last
  /// argument (`x86_64 arm64`). `null` where the host has one architecture.
  final HostCommand? binaryArchitectures;

  /// Prints `1` on an Apple Silicon Mac, even from a translated process.
  /// `null` on hosts without Rosetta.
  final HostCommand? appleSiliconCheck;

  /// Lists processes whose executable is [executableName] (with `.exe` on
  /// Windows) or whose command line runs [scriptName], one per output line
  /// that [parsePids] reads.
  HostCommand processList({
    required String executableName,
    required String scriptName,
  }) => os.isWindows
      ? (
          executable: 'tasklist',
          arguments: [
            '/FI',
            'IMAGENAME eq $executableName',
            '/FO',
            'CSV',
            '/NH',
          ],
        )
      : (
          executable: '/usr/bin/pgrep',
          arguments: ['-f', '$executableName|$scriptName'],
        );

  /// Process ids in the output of [processList].
  ///
  /// `pgrep` prints one PID per line. `tasklist` prints one CSV row per
  /// process (image name, then PID), or an informational line without a
  /// quote when none match.
  Set<int> parsePids(String output, {required String executableName}) {
    final lines = output
        .splitLines()
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty);
    if (!os.isWindows) return {...lines.map(int.tryParse).nonNulls};
    final row = '"${executableName.toLowerCase()}"';
    return {
      for (final line in lines)
        if (line.toLowerCase().startsWith(row))
          ?int.tryParse(_csvField(line, _tasklistPidColumn)),
    };
  }

  /// `tasklist /FO CSV` columns: image name, PID, session, number, memory.
  static const int _tasklistPidColumn = 1;

  static String _csvField(String row, int index) =>
      row.split(',').elementAtOrNull(index)?.replaceAll('"', '') ?? '';
}
