part of 'mcp_adb_client.dart';

/// Static operations providing device telemetry, clipboard synchronization, and file transfer.
class McpAdbDeviceOps {
  const McpAdbDeviceOps._();

  /// Extracts comprehensive hardware, OS, and battery metrics.
  static Future<Map<String, dynamic>> getDeviceInfo(
    McpAdbClient client,
    String serial,
  ) async {
    final mfg = (await client.run([
      '-s',
      serial,
      'shell',
      'getprop',
      'ro.product.manufacturer',
    ])).stdout.toString().trim();
    final model = (await client.run([
      '-s',
      serial,
      'shell',
      'getprop',
      'ro.product.model',
    ])).stdout.toString().trim();
    final osVersion = (await client.run([
      '-s',
      serial,
      'shell',
      'getprop',
      'ro.build.version.release',
    ])).stdout.toString().trim();
    final apiLevel = (await client.run([
      '-s',
      serial,
      'shell',
      'getprop',
      'ro.build.version.sdk',
    ])).stdout.toString().trim();
    final size = await client.getDisplaySize(serial);
    final densityRes = await client.run([
      '-s',
      serial,
      'shell',
      'wm',
      'density',
    ]);
    final density = densityRes.stdout.toString().trim();

    final batteryRes = await client.run([
      '-s',
      serial,
      'shell',
      'dumpsys',
      'battery',
    ]);
    final batteryOut = batteryRes.stdout.toString();
    final batteryMatch = RegExp(r'level:\s*(\d+)').firstMatch(batteryOut);
    final batteryLevel = batteryMatch != null
        ? int.parse(batteryMatch.group(1)!)
        : null;

    return {
      'manufacturer': mfg,
      'model': model,
      'androidVersion': osVersion,
      'apiLevel': apiLevel,
      'resolution': '${size.x}x${size.y}',
      'density': density,
      'batteryLevel': batteryLevel,
    };
  }

  static const String _noClipboardShell =
      'This device has no `cmd clipboard` shell command (Android 10 and 13 '
      'devices tested have none), so the clipboard cannot be read or set over '
      'adb.';

  /// The text in the Android system clipboard.
  ///
  /// Throws [McpUnsupportedOnDeviceException] when the device has no
  /// `cmd clipboard` (it still exits 0 there, see [McpShellResult]).
  static Future<String> getClipboard(McpAdbClient client, String serial) async {
    final res = await client.run([
      '-s',
      serial,
      'shell',
      'cmd',
      'clipboard',
      'get',
    ]);
    if (res.isMissingCommand) {
      throw const McpUnsupportedOnDeviceException(_noClipboardShell);
    }
    final text = res.stdout.toString().trim();
    return res.exitCode == 0 && text.isNotEmpty ? text : '';
  }

  /// Sets [text] as the Android system clipboard.
  ///
  /// Throws [McpUnsupportedOnDeviceException] when the device has no
  /// `cmd clipboard`.
  static Future<bool> setClipboard(
    McpAdbClient client,
    String serial,
    String text,
  ) async {
    final res = await client.run([
      '-s',
      serial,
      'shell',
      'cmd',
      'clipboard',
      'set',
      McpAdbTextOps.shellQuote(text),
    ]);
    if (res.isMissingCommand) {
      throw const McpUnsupportedOnDeviceException(_noClipboardShell);
    }
    return res.exitCode == 0;
  }

  /// Uploads a local file from the Mac host to the Android device.
  static Future<bool> pushFile(
    McpAdbClient client,
    String serial,
    String localPath,
    String remotePath,
  ) async {
    final res = await client.run(['-s', serial, 'push', localPath, remotePath]);
    return res.exitCode == 0;
  }

  /// Downloads a remote file from the Android device to the Mac host.
  static Future<bool> pullFile(
    McpAdbClient client,
    String serial,
    String remotePath,
    String localPath,
  ) async {
    final res = await client.run(['-s', serial, 'pull', remotePath, localPath]);
    return res.exitCode == 0;
  }

  /// Lists connected device serial numbers.
  static Future<List<String>> getConnectedSerials(McpAdbClient client) async {
    final res = await client.run(['devices']);
    if (res.exitCode != 0) return [];

    final lines = res.stdout.toString().splitLines();
    final serials = <String>[];
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('List of devices')) continue;
      final parts = trimmed.split(RegExp(r'\s+'));
      if (parts.length >= 2 && parts[1].toLowerCase() == 'device') {
        serials.add(parts[0]);
      }
    }
    return serials;
  }

  /// Returns raw ADB devices -l output.
  static Future<String> listDevicesRaw(McpAdbClient client) async {
    final res = await client.run(['devices', '-l']);
    return res.stdout.toString().trim();
  }
}
