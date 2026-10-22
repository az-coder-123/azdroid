part of 'mcp_adb_client.dart';

/// Static operations for screen video recording, process management, orientation, and biometric testing.
class McpAdbMediaProcOps {
  const McpAdbMediaProcOps._();

  /// Captures an MP4 video of the device screen and downloads it to the Mac host.
  static Future<bool> recordScreen(
    McpAdbClient client,
    String serial, {
    int durationSec = 5,
    required String localDestination,
  }) async {
    const remotePath = '/sdcard/azdroid_mcp_recording.mp4';
    final dur = durationSec.clamp(1, 180);

    // Execute screenrecord on device
    await client.run([
      '-s',
      serial,
      'shell',
      'screenrecord',
      '--time-limit',
      '$dur',
      remotePath,
    ]);

    // Download recording to local Mac
    final pullRes = await client.run([
      '-s',
      serial,
      'pull',
      remotePath,
      localDestination,
    ]);

    // Clean up temporary remote file
    await client.run(['-s', serial, 'shell', 'rm', '-f', remotePath]);

    if (pullRes.exitCode == 0) {
      final localFile = File(localDestination);
      return await localFile.exists() && (await localFile.length()) > 0;
    }
    return false;
  }

  /// Lists active Android processes with PID, virtual memory, and process name.
  static Future<List<Map<String, String>>> listProcesses(
    McpAdbClient client,
    String serial, {
    String? filter,
  }) async {
    final res = await client.run(['-s', serial, 'shell', 'ps', '-A']);
    if (res.exitCode != 0) return [];

    final lines = res.stdout.toString().splitLines();
    final results = <Map<String, String>>[];

    for (int i = 1; i < lines.length; i++) {
      final parts = lines[i].trim().split(RegExp(r'\s+'));
      if (parts.length >= 9) {
        final pid = parts[1];
        final name = parts[8];
        if (filter == null ||
            name.toLowerCase().contains(filter.toLowerCase())) {
          results.add({'pid': pid, 'name': name});
        }
      }
    }
    return results;
  }

  /// Terminates a process by its PID or package identifier.
  static Future<bool> killProcess(
    McpAdbClient client,
    String serial, {
    int? pid,
    String? package,
  }) async {
    if (pid != null) {
      final res = await client.run([
        '-s',
        serial,
        'shell',
        'kill',
        '-9',
        '$pid',
      ]);
      return res.exitCode == 0;
    }
    if (package != null && package.isNotEmpty) {
      final res = await client.run([
        '-s',
        serial,
        'shell',
        'am',
        'force-stop',
        package,
      ]);
      return res.exitCode == 0;
    }
    return false;
  }

  /// Fixes screen orientation to 0 (portrait), 1 (landscape), 2 (reverse portrait), or 3 (reverse landscape).
  static Future<bool> setOrientation(
    McpAdbClient client,
    String serial,
    int orientation,
  ) async {
    final validOrientation = orientation.clamp(0, 3);
    await client.run([
      '-s',
      serial,
      'shell',
      'settings',
      'put',
      'system',
      'accelerometer_rotation',
      '0',
    ]);
    final res = await client.run([
      '-s',
      serial,
      'shell',
      'settings',
      'put',
      'system',
      'user_rotation',
      '$validOrientation',
    ]);
    return res.exitCode == 0;
  }

  /// Touches the emulator's fingerprint sensor with an enrolled finger
  /// ([success]) or an unknown one.
  ///
  /// Only emulators can fake biometrics over adb (`adb emu finger touch`);
  /// real devices have no shell command for it (`cmd fingerprint` and
  /// `cmd biometric` are missing on the Android 10 and 13 devices tested).
  static Future<bool> simulateBiometric(
    McpAdbClient client,
    String serial, {
    bool success = true,
  }) async {
    if (!isEmulator(serial)) {
      throw const McpUnsupportedOnDeviceException(
        'Biometric simulation works only on Android emulators (adb emu '
        'finger touch). Physical devices have no adb command for it.',
      );
    }
    final res = await client.run([
      '-s',
      serial,
      'emu',
      'finger',
      'touch',
      success ? _enrolledFingerId : _unknownFingerId,
    ]);
    return res.exitCode == 0;
  }

  /// Finger id enrolled first in emulator Settings, and one never enrolled.
  static const String _enrolledFingerId = '1';
  static const String _unknownFingerId = '9';

  /// Serials of local emulators (`emulator-5554`), which accept `adb emu`.
  static bool isEmulator(String serial) => serial.startsWith('emulator-');
}
