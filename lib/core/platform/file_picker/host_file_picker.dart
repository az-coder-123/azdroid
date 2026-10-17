import 'package:file_selector/file_selector.dart' as fs;

/// Contract for native open-file dialogs on the host OS.
abstract class HostFilePicker {
  /// Lets the user pick one or more files. Returns an empty list on cancel.
  Future<List<String>> pickFiles();

  /// Lets the user pick a single `.apk` file. Returns `null` on cancel.
  Future<String?> pickApkFile();
}

/// Signature of `file_selector.openFiles`, injectable for tests.
typedef OpenFilesFn = Future<List<fs.XFile>> Function({
  List<fs.XTypeGroup> acceptedTypeGroups,
  String? confirmButtonText,
  String? initialDirectory,
});

/// Signature of `file_selector.openFile`, injectable for tests.
typedef OpenFileFn = Future<fs.XFile?> Function({
  List<fs.XTypeGroup> acceptedTypeGroups,
  String? confirmButtonText,
  String? initialDirectory,
});

/// [HostFilePicker] for every desktop OS, backed by `package:file_selector`.
///
/// One implementation serves macOS and Windows: the plugin maps each call to
/// `NSOpenPanel` or `IFileOpenDialog`, so no OS-specific code lives here.
class FileSelectorHostFilePicker implements HostFilePicker {
  const FileSelectorHostFilePicker({
    this._openFiles = fs.openFiles,
    this._openFile = fs.openFile,
  });

  /// Button label shown when sending files to the device.
  static const String sendButtonText = 'Send to Android';

  /// Button label shown when choosing an APK to install.
  static const String installButtonText = 'Inspect APK';

  /// File type filter for Android packages.
  static const fs.XTypeGroup apkTypeGroup = fs.XTypeGroup(
    label: 'Android Package',
    extensions: ['apk'],
  );

  final OpenFilesFn _openFiles;
  final OpenFileFn _openFile;

  @override
  Future<List<String>> pickFiles() async {
    final files = await _openFiles(confirmButtonText: sendButtonText);
    return [for (final file in files) file.path];
  }

  @override
  Future<String?> pickApkFile() async {
    final file = await _openFile(
      acceptedTypeGroups: const [apkTypeGroup],
      confirmButtonText: installButtonText,
    );
    return file?.path;
  }
}
