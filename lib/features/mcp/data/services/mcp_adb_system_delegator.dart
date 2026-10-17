part of 'mcp_adb_client.dart';

/// Mixin providing system, telemetry, settings, media, and UI inspection
/// delegator methods for [McpAdbClient].
mixin McpAdbSystemDelegator {
  McpAdbClient get _adbClient => this as McpAdbClient;

  // --- UI Inspection & Semantic Operations ---
  Future<String> dumpHierarchy(String serial) =>
      McpAdbUiOps.dumpHierarchy(_adbClient, serial);

  Future<String> getSemanticTree(String serial) =>
      McpAdbUiOps.getSemanticTree(_adbClient, serial);

  Future<bool> clickElementById(String serial, int id) =>
      McpAdbUiOps.clickElementById(_adbClient, serial, id);

  Future<Map<String, dynamic>?> findElement(
    String serial, {
    String? text,
    String? resourceId,
    String? contentDesc,
  }) => McpAdbUiOps.findElement(
    _adbClient,
    serial,
    text: text,
    resourceId: resourceId,
    contentDesc: contentDesc,
  );

  Future<bool> clickElement(
    String serial, {
    String? text,
    String? resourceId,
    String? contentDesc,
  }) => McpAdbUiOps.clickElement(
    _adbClient,
    serial,
    text: text,
    resourceId: resourceId,
    contentDesc: contentDesc,
  );

  // --- System, Radio & Settings Operations ---
  Future<bool> toggleWifi(String serial, bool enable) =>
      McpAdbSystemOps.toggleWifi(_adbClient, serial, enable);

  Future<bool> toggleAirplaneMode(String serial, bool enable) =>
      McpAdbSystemOps.toggleAirplaneMode(_adbClient, serial, enable);

  Future<bool> grantPermission(
    String serial,
    String packageName,
    String permission,
  ) => McpAdbSystemOps.grantPermission(
    _adbClient,
    serial,
    packageName,
    permission,
  );

  Future<bool> revokePermission(
    String serial,
    String packageName,
    String permission,
  ) => McpAdbSystemOps.revokePermission(
    _adbClient,
    serial,
    packageName,
    permission,
  );

  Future<bool> setVolume(
    String serial, {
    required int stream,
    required int volumeIndex,
  }) => McpAdbSystemOps.setVolume(
    _adbClient,
    serial,
    stream: stream,
    volumeIndex: volumeIndex,
  );

  Future<bool> wakeOrSleep(String serial, bool wake) =>
      McpAdbSystemOps.wakeOrSleep(_adbClient, serial, wake);

  Future<String> openSettings(
    String serial, {
    String? action,
    String? packageName,
  }) => McpAdbSystemOps.openSettings(
    _adbClient,
    serial,
    action: action,
    packageName: packageName,
  );

  // --- Performance & Hardware Telemetry Operations ---
  Future<String> getCpuUsage(String serial, {String? package}) =>
      McpAdbPerformanceOps.getCpuUsage(_adbClient, serial, package: package);

  Future<String> getMemoryInfo(String serial, String package) =>
      McpAdbPerformanceOps.getMemoryInfo(_adbClient, serial, package);

  Future<Map<String, dynamic>> getBatteryStats(String serial) =>
      McpAdbPerformanceOps.getBatteryStats(_adbClient, serial);

  Future<String> getGfxInfo(String serial, String package) =>
      McpAdbPerformanceOps.getGfxInfo(_adbClient, serial, package);

  Future<Map<String, String>> getNetworkInfo(String serial) =>
      McpAdbPerformanceOps.getNetworkInfo(_adbClient, serial);

  // --- Media Recording, Process & Biometrics Operations ---
  Future<bool> recordScreen(
    String serial, {
    int durationSec = 5,
    required String localDestination,
  }) => McpAdbMediaProcOps.recordScreen(
    _adbClient,
    serial,
    durationSec: durationSec,
    localDestination: localDestination,
  );

  Future<List<Map<String, String>>> listProcesses(
    String serial, {
    String? filter,
  }) => McpAdbMediaProcOps.listProcesses(_adbClient, serial, filter: filter);

  Future<bool> killProcess(String serial, {int? pid, String? package}) =>
      McpAdbMediaProcOps.killProcess(
        _adbClient,
        serial,
        pid: pid,
        package: package,
      );

  Future<bool> setOrientation(String serial, int orientation) =>
      McpAdbMediaProcOps.setOrientation(_adbClient, serial, orientation);

  Future<bool> simulateBiometric(String serial, {bool success = true}) =>
      McpAdbMediaProcOps.simulateBiometric(
        _adbClient,
        serial,
        success: success,
      );
}
