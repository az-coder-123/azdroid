import 'package:desk_droid/core/platform/host_os.dart';
import 'package:desk_droid/core/platform/host_paths.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SystemHostPaths on macOS', () {
    final paths = SystemHostPaths(
      os: HostOs.macos,
      environment: {'HOME': '/Users/dev'},
      systemTempPath: '/var/folders/xy/T',
    );

    test('resolves home, downloads, and app data', () {
      expect(paths.homeDirectory, '/Users/dev');
      expect(paths.downloadsDirectory, '/Users/dev/Downloads');
      expect(
        paths.appDataDirectory,
        '/Users/dev/Library/Application Support/Azdroid',
      );
    });

    test('keeps the diagnostic log in /tmp', () {
      expect(paths.diagnosticLogFile, '/tmp/azdroid_dart.log');
    });
  });

  group('SystemHostPaths on Windows', () {
    final paths = SystemHostPaths(
      os: HostOs.windows,
      environment: {
        'USERPROFILE': r'C:\Users\Nguyễn Văn A',
        'APPDATA': r'C:\Users\Nguyễn Văn A\AppData\Roaming',
      },
      systemTempPath: r'C:\Users\Nguyễn Văn A\AppData\Local\Temp',
    );

    test('uses USERPROFILE and APPDATA with backslashes', () {
      expect(paths.homeDirectory, r'C:\Users\Nguyễn Văn A');
      expect(paths.downloadsDirectory, r'C:\Users\Nguyễn Văn A\Downloads');
      expect(
        paths.appDataDirectory,
        r'C:\Users\Nguyễn Văn A\AppData\Roaming\Azdroid',
      );
    });

    test('writes the diagnostic log to the system temp folder', () {
      expect(
        paths.diagnosticLogFile,
        r'C:\Users\Nguyễn Văn A\AppData\Local\Temp\azdroid_dart.log',
      );
    });

    test('falls back to HOMEDRIVE and HOMEPATH', () {
      final fallback = SystemHostPaths(
        os: HostOs.windows,
        environment: {'HOMEDRIVE': 'D:', 'HOMEPATH': r'\Users\dev'},
        systemTempPath: r'D:\Temp',
      );
      expect(fallback.homeDirectory, r'D:\Users\dev');
      expect(
        fallback.appDataDirectory,
        r'D:\Users\dev\AppData\Roaming\Azdroid',
      );
    });
  });

  test('Linux honors XDG_DATA_HOME', () {
    final paths = SystemHostPaths(
      os: HostOs.linux,
      environment: {'HOME': '/home/dev', 'XDG_DATA_HOME': '/data'},
      systemTempPath: '/tmp',
    );
    expect(paths.appDataDirectory, '/data/Azdroid');
  });

  test('HostOs.executableName appends .exe only on Windows', () {
    expect(HostOs.windows.executableName('adb'), 'adb.exe');
    expect(HostOs.macos.executableName('adb'), 'adb');
  });

  group('flutterAssetPath', () {
    test('macOS resolves inside App.framework of the .app bundle', () {
      final paths = SystemHostPaths(
        os: HostOs.macos,
        environment: {'HOME': '/Users/dev'},
        systemTempPath: '/tmp',
        executablePath: '/Applications/Azdroid.app/Contents/MacOS/Azdroid',
      );
      expect(
        paths.flutterAssetPath('assets/scrcpy-server.jar'),
        '/Applications/Azdroid.app/Contents/Frameworks/App.framework/'
        'Versions/A/Resources/flutter_assets/assets/scrcpy-server.jar',
      );
    });

    test('Windows resolves under data/flutter_assets next to the exe', () {
      final paths = SystemHostPaths(
        os: HostOs.windows,
        environment: {'USERPROFILE': r'C:\Users\dev'},
        systemTempPath: r'C:\Temp',
        executablePath: r'C:\Program Files\Azdroid\desk_droid.exe',
      );
      expect(
        paths.flutterAssetPath('assets/scrcpy-server.jar'),
        r'C:\Program Files\Azdroid\data\flutter_assets\assets\scrcpy-server.jar',
      );
    });
  });

  test('executableDirectory is the folder of the running executable', () {
    final mac = SystemHostPaths(
      os: HostOs.macos,
      environment: {'HOME': '/Users/dev'},
      systemTempPath: '/tmp',
      executablePath: '/Applications/Azdroid.app/Contents/MacOS/Azdroid',
    );
    final win = SystemHostPaths(
      os: HostOs.windows,
      environment: {'USERPROFILE': r'C:\Users\dev'},
      systemTempPath: r'C:\Temp',
      executablePath: r'C:\Program Files\Azdroid\desk_droid.exe',
    );

    expect(mac.executableDirectory, '/Applications/Azdroid.app/Contents/MacOS');
    expect(win.executableDirectory, r'C:\Program Files\Azdroid');
  });
}
