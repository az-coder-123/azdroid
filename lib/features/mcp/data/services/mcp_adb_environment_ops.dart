part of 'mcp_adb_client.dart';

/// Implements Mock Location, Network Conditioning, and Long Press gestures for ADB MCP.
class McpAdbEnvironmentOps {
  const McpAdbEnvironmentOps._();

  /// Location providers replaced by the mock location.
  static const List<String> _mockProviders = ['gps', 'network'];
  static const String _shellPackage = 'com.android.shell';
  static const String _mockLocationOp = 'android:mock_location';

  /// Replaces the device location for every app with ([latitude],
  /// [longitude]) until [resetLocation].
  ///
  /// Emulators use `adb emu geo fix`. Devices need Android 12+ (`cmd
  /// location providers`, present on Android 13, missing on Android 10) and
  /// location turned on; the tool does not change that setting. Throws
  /// [McpUnsupportedOnDeviceException] with the reason otherwise.
  static Future<void> setLocation(
    McpAdbClient client,
    String serial, {
    required double latitude,
    required double longitude,
  }) async {
    if (McpAdbMediaProcOps.isEmulator(serial)) {
      final res = await client.run([
        '-s', serial, 'emu', 'geo', 'fix', '$longitude', '$latitude', //
      ]);
      _ensure(res, 'adb emu geo fix');
      return;
    }
    await _ensureLocationEnabled(client, serial);
    _ensure(
      await _shell(client, serial, [
        'appops', 'set', _shellPackage, _mockLocationOp, 'allow', //
      ]),
      'appops set mock_location',
    );
    for (final provider in _mockProviders) {
      // Re-adding an existing test provider fails, so start clean.
      await _location(client, serial, ['remove-test-provider', provider]);
      _ensure(
        await _location(client, serial, ['add-test-provider', provider]),
        'add-test-provider $provider',
      );
      _ensure(
        await _location(client, serial, [
          'set-test-provider-enabled', provider, 'true', //
        ]),
        'set-test-provider-enabled $provider',
      );
      _ensure(
        await _location(client, serial, [
          'set-test-provider-location',
          provider,
          '--location',
          '$latitude,$longitude',
        ]),
        'set-test-provider-location $provider',
      );
    }
  }

  /// Removes the mock location and the shell's mock-location permission, so
  /// the device reports its real location again. No-op on emulators.
  static Future<void> resetLocation(McpAdbClient client, String serial) async {
    if (McpAdbMediaProcOps.isEmulator(serial)) return;
    for (final provider in _mockProviders) {
      final res = await _location(client, serial, [
        'remove-test-provider', provider, //
      ]);
      if (res.isMissingCommand) throw _noLocationShell;
    }
    _ensure(
      await _shell(client, serial, [
        'appops', 'set', _shellPackage, _mockLocationOp, 'default', //
      ]),
      'appops reset mock_location',
    );
  }

  static const McpUnsupportedOnDeviceException _noLocationShell =
      McpUnsupportedOnDeviceException(
        'Mock locations over adb need Android 12 or later (`cmd location '
        'providers`); this device has no `cmd location`. Emulators work on any '
        'version.',
      );

  static Future<void> _ensureLocationEnabled(
    McpAdbClient client,
    String serial,
  ) async {
    final res = await _shell(client, serial, [
      'cmd', 'location', 'is-location-enabled', //
    ]);
    if (res.isMissingCommand) throw _noLocationShell;
    if (res.stdout.toString().trim() != 'true') {
      throw const McpUnsupportedOnDeviceException(
        'Location is turned off on the device. Turn it on in Settings first; '
        'android_set_location does not change that setting.',
      );
    }
  }

  static Future<ProcessResult> _location(
    McpAdbClient client,
    String serial,
    List<String> providerArgs,
  ) =>
      _shell(client, serial, ['cmd', 'location', 'providers', ...providerArgs]);

  static Future<ProcessResult> _shell(
    McpAdbClient client,
    String serial,
    List<String> args,
  ) => client.run(['-s', serial, 'shell', ...args]);

  /// Throws with the device's own message when [res] did not succeed.
  static void _ensure(ProcessResult res, String step) {
    if (res.isMissingCommand) throw _noLocationShell;
    if (!res.succeeded) {
      final detail = '${res.stderr}${res.stdout}'.trim();
      throw McpUnsupportedOnDeviceException(
        'Mock location failed at "$step": $detail',
      );
    }
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
