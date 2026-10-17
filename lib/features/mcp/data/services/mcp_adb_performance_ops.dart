part of 'mcp_adb_client.dart';

/// Static operations for hardware performance telemetry, memory profiling, CPU sampling, and battery diagnostics.
class McpAdbPerformanceOps {
  const McpAdbPerformanceOps._();

  /// Retrieves CPU consumption metrics for a specific package or the entire system.
  static Future<String> getCpuUsage(
    McpAdbClient client,
    String serial, {
    String? package,
  }) async {
    if (package != null && package.isNotEmpty) {
      final res = await client.run([
        '-s',
        serial,
        'shell',
        'dumpsys',
        'cpuinfo',
      ]);
      final lines = res.stdout.toString().splitLines();
      final matched = lines
          .where((l) => l.toLowerCase().contains(package.toLowerCase()))
          .join('\n');
      return matched.isNotEmpty
          ? matched
          : 'No active CPU consumption detected for $package.';
    }

    final topRes = await client.run([
      '-s',
      serial,
      'shell',
      'top',
      '-n',
      '1',
      '-b',
      '-m',
      '10',
    ]);
    return topRes.stdout.toString().trim();
  }

  /// Dumps detailed PSS, Dalvik, and Native heap memory allocation for a package.
  static Future<String> getMemoryInfo(
    McpAdbClient client,
    String serial,
    String package,
  ) async {
    final res = await client.run([
      '-s',
      serial,
      'shell',
      'dumpsys',
      'meminfo',
      package,
    ]);
    return res.stdout.toString().trim();
  }

  /// Extracts comprehensive battery health, voltage, temperature, and charging status.
  static Future<Map<String, dynamic>> getBatteryStats(
    McpAdbClient client,
    String serial,
  ) async {
    final res = await client.run(['-s', serial, 'shell', 'dumpsys', 'battery']);
    final out = res.stdout.toString();

    int? getInt(String key) {
      final match = RegExp('$key:\\s*(\\d+)').firstMatch(out);
      return match != null ? int.tryParse(match.group(1)!) : null;
    }

    bool? getBool(String key) {
      final match = RegExp('$key:\\s*(true|false)').firstMatch(out);
      return match != null ? match.group(1) == 'true' : null;
    }

    final rawTemp = getInt('temperature');
    final tempCelsius = rawTemp != null ? rawTemp / 10.0 : null;

    return {
      'acPowered': getBool('AC powered'),
      'usbPowered': getBool('USB powered'),
      'wirelessPowered': getBool('Wireless powered'),
      'level': getInt('level'),
      'scale': getInt('scale'),
      'voltageMv': getInt('voltage'),
      'temperatureCelsius': tempCelsius,
      'technology': RegExp(r'technology:\s*([^\r\n]+)')
          .firstMatch(out)
          ?.group(1)
          ?.trim(),
      'status': getInt('status'),
      'health': getInt('health'),
    };
  }

  /// Queries Android Choreographer / RenderThread frame rendering metrics and jank analysis.
  static Future<String> getGfxInfo(
    McpAdbClient client,
    String serial,
    String package,
  ) async {
    final res = await client.run([
      '-s',
      serial,
      'shell',
      'dumpsys',
      'gfxinfo',
      package,
    ]);
    final out = res.stdout.toString().trim();
    return out.isNotEmpty
        ? out
        : 'No graphics telemetry available for $package.';
  }

  /// Discovers IP addresses, Wi-Fi link speed, and MAC hardware address.
  static Future<Map<String, String>> getNetworkInfo(
    McpAdbClient client,
    String serial,
  ) async {
    final ipRes = await client.run([
      '-s',
      serial,
      'shell',
      'ip',
      'addr',
      'show',
      'wlan0',
    ]);
    final ipOut = ipRes.stdout.toString();
    final inetMatch = RegExp(r'inet\s+(\d+\.\d+\.\d+\.\d+)/(\d+)')
        .firstMatch(ipOut);
    final ipAddress = inetMatch?.group(1) ?? 'Unknown';

    final wifiRes = await client.run([
      '-s',
      serial,
      'shell',
      'dumpsys',
      'wifi',
    ]);
    final wifiOut = wifiRes.stdout.toString();
    final ssidMatch = RegExp(r'SSID:\s*([^,\n]+)').firstMatch(wifiOut);
    final linkSpeedMatch = RegExp(r'Link speed:\s*(\d+\s*Mbps)')
        .firstMatch(wifiOut);

    return {
      'ipAddress': ipAddress,
      'ssid': ssidMatch?.group(1)?.replaceAll('"', '') ?? 'Unknown',
      'linkSpeed': linkSpeedMatch?.group(1) ?? 'Unknown',
    };
  }
}
