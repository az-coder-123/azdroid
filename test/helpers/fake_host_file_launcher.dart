import 'package:desk_droid/core/platform/file_launcher/host_file_launcher.dart';

/// [HostFileLauncher] that records calls and never touches the OS shell.
class FakeHostFileLauncher implements HostFileLauncher {
  final List<String> opened = [];
  final List<String> revealed = [];

  @override
  Future<bool> open(String path) async {
    opened.add(path);
    return true;
  }

  @override
  Future<bool> reveal(String path) async {
    revealed.add(path);
    return true;
  }
}
