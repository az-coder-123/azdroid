import 'package:wifi_desk/core/services/app_logger.dart';
import 'package:wifi_desk/core/services/process_executor.dart';

/// Contract for native macOS file and directory picker interactions.
abstract class MacFilePickerService {
  /// Opens the native macOS Finder file selection sheet with multi-select enabled.
  Future<List<String>> pickFiles({String prompt});

  /// Opens the native macOS Finder folder selection sheet.
  Future<String?> pickDirectory({String prompt});
}

/// Concrete implementation utilizing macOS `osascript` to invoke native Apple Finder panels.
class MacFilePickerServiceImpl implements MacFilePickerService {
  const MacFilePickerServiceImpl({
    ProcessExecutor processExecutor = const DefaultProcessExecutor(),
  }) : _executor = processExecutor;

  final ProcessExecutor _executor;

  @override
  Future<List<String>> pickFiles({
    String prompt = 'Select files to send to Android',
  }) async {
    final script =
        '''
try
  set theFiles to choose file with multiple selections allowed with prompt "$prompt"
  set pathList to {}
  repeat with aFile in theFiles
    set end of pathList to POSIX path of aFile
  end repeat
  set AppleScript's text item delimiters to ASCII character 10
  return pathList as text
on error
  return ""
end try
''';

    try {
      final result = await _executor.run('osascript', ['-e', script]);
      if (result.exitCode != 0) return [];

      final output = result.stdout.toString().trim();
      if (output.isEmpty) return [];

      return output
          .split('\n')
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty)
          .toList();
    } catch (e, stack) {
      AppLogger.warning(
        'Failed to open macOS file picker: $e',
        error: e,
        stackTrace: stack,
      );
      return [];
    }
  }

  @override
  Future<String?> pickDirectory({
    String prompt = 'Select destination folder',
  }) async {
    final script =
        '''
try
  set theFolder to choose folder with prompt "$prompt"
  return POSIX path of theFolder
on error
  return ""
end try
''';

    try {
      final result = await _executor.run('osascript', ['-e', script]);
      if (result.exitCode != 0) return null;

      final output = result.stdout.toString().trim();
      return output.isNotEmpty ? output : null;
    } catch (e, stack) {
      AppLogger.warning(
        'Failed to open macOS directory picker: $e',
        error: e,
        stackTrace: stack,
      );
      return null;
    }
  }
}
