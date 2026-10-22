part of 'mcp_adb_client.dart';

/// Implements Mock Location, Network Conditioning, and Long Press gestures for ADB MCP.
class McpAdbEnvironmentOps {
  const McpAdbEnvironmentOps._();

  static Future<bool> setLocation(
    McpAdbClient client,
    String serial, {
    required double latitude,
    required double longitude,
    double? altitude,
  }) async {
    await client.run([
      '-s',
      serial,
      'shell',
      'settings',
      'put',
      'secure',
      'location_mode',
      '3',
    ]);
    final res = await client.run([
      '-s',
      serial,
      'shell',
      'cmd',
      'location',
      'set-location',
      latitude.toString(),
      longitude.toString(),
      if (altitude != null) altitude.toString(),
    ]);
    if (res.exitCode == 0) return true;
    final emu = await client.run([
      '-s',
      serial,
      'emu',
      'geo',
      'fix',
      longitude.toString(),
      latitude.toString(),
    ]);
    return emu.exitCode == 0;
  }

  static Future<bool> setNetworkCondition(
    McpAdbClient client,
    String serial,
    String mode,
  ) async {
    switch (mode.toLowerCase()) {
      case 'offline':
        await client.run(['-s', serial, 'shell', 'svc', 'wifi', 'disable']);
        await client.run(['-s', serial, 'shell', 'svc', 'data', 'disable']);
      case 'wifi_only':
        await client.run(['-s', serial, 'shell', 'svc', 'wifi', 'enable']);
        await client.run(['-s', serial, 'shell', 'svc', 'data', 'disable']);
      case 'data_only':
        await client.run(['-s', serial, 'shell', 'svc', 'wifi', 'disable']);
        await client.run(['-s', serial, 'shell', 'svc', 'data', 'enable']);
      default:
        await client.run(['-s', serial, 'shell', 'svc', 'wifi', 'enable']);
        await client.run(['-s', serial, 'shell', 'svc', 'data', 'enable']);
    }
    return true;
  }

  static Future<bool> longPress(
    McpAdbClient client,
    String serial,
    McpPoint point, {
    int durationMs = 1000,
  }) =>
      // A swipe that does not move is a long press.
      client.swipe(serial, point, point, durationMs);
}
