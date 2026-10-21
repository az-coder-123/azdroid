import 'package:desk_droid/core/platform/host_os.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_toolchains.dart';

void main() {
  test('macOS uses which, plain names, and Homebrew fallbacks', () {
    final mac = toolchainFor(HostOs.macos, {'HOME': '/Users/dev'});

    expect(mac.pathLookupCommand, '/usr/bin/which');
    expect(mac.aaptExecutables, ['aapt2', 'aapt']);
    expect(mac.adbSearchPaths, [
      '/Users/dev/Library/Android/sdk/platform-tools/adb',
      '/opt/homebrew/bin/adb',
      '/usr/local/bin/adb',
      // Bundled copy is the last resort, so an installed adb always wins.
      '/Applications/Azdroid.app/Contents/MacOS/adb',
    ]);
    expect(mac.arpArguments, ['-an']);
  });

  test('Windows uses where, .exe names, and LOCALAPPDATA SDK', () {
    final win = toolchainFor(HostOs.windows, {
      'USERPROFILE': r'C:\Users\dev',
      'LOCALAPPDATA': r'C:\Users\dev\AppData\Local',
    });

    expect(win.pathLookupCommand, 'where');
    expect(win.adbExecutable, 'adb.exe');
    expect(win.aaptExecutables, ['aapt2.exe', 'aapt.exe']);
    expect(win.buildToolsDirectories, [
      r'C:\Users\dev\AppData\Local\Android\Sdk\build-tools',
    ]);
    expect(win.adbSearchPaths.last, r'C:\Program Files\Azdroid\adb.exe');
    expect(win.arpCommand, 'arp');
    expect(win.arpArguments, ['-a']);
  });

  test('ANDROID_HOME takes precedence over the default SDK root', () {
    final mac = toolchainFor(HostOs.macos, {
      'HOME': '/Users/dev',
      'ANDROID_HOME': '/sdk',
    });

    expect(mac.androidSdkRoots.first, '/sdk');
    expect(mac.adbSearchPaths.first, '/sdk/platform-tools/adb');
  });
}
