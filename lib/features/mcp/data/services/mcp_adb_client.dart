import 'dart:io';

part 'mcp_adb_app_ops.dart';
part 'mcp_adb_cmd_ops.dart';
part 'mcp_adb_device_ops.dart';
part 'mcp_adb_input_ops.dart';
part 'mcp_adb_media_proc_ops.dart';
part 'mcp_adb_performance_ops.dart';
part 'mcp_adb_resolver.dart';
part 'mcp_adb_system_ops.dart';
part 'mcp_adb_ui_ops.dart';

/// Pure Dart ADB client for DeskDroid MCP Server.
/// Operates without UI or Flutter framework dependencies.
class McpAdbClient {
  McpAdbClient({String? explicitAdbPath}) : _cachedAdbPath = explicitAdbPath;

  String? _cachedAdbPath;

  Future<String?> resolveAdb() async =>
      _cachedAdbPath = await McpAdbResolver.resolve(_cachedAdbPath);

  Future<ProcessResult> run(List<String> args) async {
    final adb = await resolveAdb();
    if (adb == null) {
      throw const SocketException('ADB executable not found on host machine.');
    }
    return await Process.run(adb, args);
  }

  // --- Device Enumeration ---
  Future<List<String>> getConnectedSerials() =>
      McpAdbDeviceOps.getConnectedSerials(this);

  Future<String> listDevicesRaw() => McpAdbDeviceOps.listDevicesRaw(this);

  // --- Input & Gesture Operations ---
  Future<List<int>?> captureScreenshotBytes(String serial) =>
      McpAdbInputOps.captureScreenshotBytes(this, serial);

  Future<Point<int>> getDisplaySize(String serial) =>
      McpAdbInputOps.getDisplaySize(this, serial);

  Future<bool> tap(String serial, double x, double y) =>
      McpAdbInputOps.tap(this, serial, x, y);

  Future<bool> swipe(
    String serial,
    double sx,
    double sy,
    double ex,
    double ey,
    int durationMs,
  ) => McpAdbInputOps.swipe(this, serial, sx, sy, ex, ey, durationMs);

  Future<bool> typeText(String serial, String text) =>
      McpAdbInputOps.typeText(this, serial, text);

  Future<bool> pressKey(String serial, int keyCode) =>
      McpAdbInputOps.pressKey(this, serial, keyCode);

  // --- Command & Diagnostic Operations ---
  Future<String> dispatchIntent(
    String serial,
    String action, {
    String? dataUri,
    String? package,
    String? component,
    Map<String, dynamic>? extras,
  }) => McpAdbCmdOps.dispatchIntent(
    this,
    serial,
    action,
    dataUri: dataUri,
    package: package,
    component: component,
    extras: extras,
  );

  Future<String> getLogcat(String serial, {String? tag, int limit = 50}) =>
      McpAdbCmdOps.getLogcat(this, serial, tag: tag, limit: limit);

  Future<bool> installApk(
    String serial,
    String apkPath, {
    bool reinstall = true,
    bool grantPermissions = true,
  }) => McpAdbCmdOps.installApk(
    this,
    serial,
    apkPath,
    reinstall: reinstall,
    grantPermissions: grantPermissions,
  );

  Future<String> shell(String serial, String command) =>
      McpAdbCmdOps.shell(this, serial, command);

  // --- App Lifecycle Operations ---
  Future<Map<String, String>?> getCurrentApp(String serial) =>
      McpAdbAppOps.getCurrentApp(this, serial);

  Future<bool> launchApp(String serial, String packageName) =>
      McpAdbAppOps.launchApp(this, serial, packageName);

  Future<bool> stopApp(String serial, String packageName) =>
      McpAdbAppOps.stopApp(this, serial, packageName);

  Future<bool> clearAppData(String serial, String packageName) =>
      McpAdbAppOps.clearAppData(this, serial, packageName);

  Future<List<String>> listPackages(
    String serial, {
    bool thirdPartyOnly = true,
    String? query,
  }) => McpAdbAppOps.listPackages(
    this,
    serial,
    thirdPartyOnly: thirdPartyOnly,
    query: query,
  );

  // --- Device & File Transfer Operations ---
  Future<Map<String, dynamic>> getDeviceInfo(String serial) =>
      McpAdbDeviceOps.getDeviceInfo(this, serial);

  Future<String> getClipboard(String serial) =>
      McpAdbDeviceOps.getClipboard(this, serial);

  Future<bool> setClipboard(String serial, String text) =>
      McpAdbDeviceOps.setClipboard(this, serial, text);

  Future<bool> pushFile(String serial, String localPath, String remotePath) =>
      McpAdbDeviceOps.pushFile(this, serial, localPath, remotePath);

  Future<bool> pullFile(String serial, String remotePath, String localPath) =>
      McpAdbDeviceOps.pullFile(this, serial, remotePath, localPath);

  // --- UI Semantic & Accessibility Operations ---
  Future<String> dumpHierarchy(String serial) =>
      McpAdbUiOps.dumpHierarchy(this, serial);

  Future<Map<String, dynamic>?> findElement(
    String serial, {
    String? text,
    String? resourceId,
    String? contentDesc,
  }) => McpAdbUiOps.findElement(
    this,
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
    this,
    serial,
    text: text,
    resourceId: resourceId,
    contentDesc: contentDesc,
  );

  // --- System, Radio & Settings Operations ---
  Future<bool> toggleWifi(String serial, bool enable) =>
      McpAdbSystemOps.toggleWifi(this, serial, enable);

  Future<bool> toggleAirplaneMode(String serial, bool enable) =>
      McpAdbSystemOps.toggleAirplaneMode(this, serial, enable);

  Future<bool> grantPermission(
    String serial,
    String packageName,
    String permission,
  ) => McpAdbSystemOps.grantPermission(this, serial, packageName, permission);

  Future<bool> revokePermission(
    String serial,
    String packageName,
    String permission,
  ) => McpAdbSystemOps.revokePermission(this, serial, packageName, permission);

  Future<bool> setVolume(
    String serial, {
    required int stream,
    required int volumeIndex,
  }) => McpAdbSystemOps.setVolume(
    this,
    serial,
    stream: stream,
    volumeIndex: volumeIndex,
  );

  Future<bool> wakeOrSleep(String serial, bool wake) =>
      McpAdbSystemOps.wakeOrSleep(this, serial, wake);

  Future<String> openSettings(
    String serial, {
    String? action,
    String? packageName,
  }) => McpAdbSystemOps.openSettings(
    this,
    serial,
    action: action,
    packageName: packageName,
  );

  // --- Performance & Hardware Telemetry Operations ---
  Future<String> getCpuUsage(String serial, {String? package}) =>
      McpAdbPerformanceOps.getCpuUsage(this, serial, package: package);
  Future<String> getMemoryInfo(String serial, String package) =>
      McpAdbPerformanceOps.getMemoryInfo(this, serial, package);
  Future<Map<String, dynamic>> getBatteryStats(String serial) =>
      McpAdbPerformanceOps.getBatteryStats(this, serial);
  Future<String> getGfxInfo(String serial, String package) =>
      McpAdbPerformanceOps.getGfxInfo(this, serial, package);
  Future<Map<String, String>> getNetworkInfo(String serial) =>
      McpAdbPerformanceOps.getNetworkInfo(this, serial);

  // --- Media Recording, Process & Biometrics Operations ---
  Future<bool> recordScreen(
    String serial, {
    int durationSec = 5,
    required String localDestination,
  }) => McpAdbMediaProcOps.recordScreen(
    this,
    serial,
    durationSec: durationSec,
    localDestination: localDestination,
  );
  Future<List<Map<String, String>>> listProcesses(
    String serial, {
    String? filter,
  }) => McpAdbMediaProcOps.listProcesses(this, serial, filter: filter);
  Future<bool> killProcess(String serial, {int? pid, String? package}) =>
      McpAdbMediaProcOps.killProcess(this, serial, pid: pid, package: package);
  Future<bool> setOrientation(String serial, int orientation) =>
      McpAdbMediaProcOps.setOrientation(this, serial, orientation);
  Future<bool> simulateBiometric(String serial, {bool success = true}) =>
      McpAdbMediaProcOps.simulateBiometric(this, serial, success: success);
}
