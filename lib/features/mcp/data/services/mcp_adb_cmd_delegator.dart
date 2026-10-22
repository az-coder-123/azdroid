part of 'mcp_adb_client.dart';

/// Mixin delegating intent, logcat, crash, install, and shell operations
/// ([McpAdbCmdOps]) for [McpAdbClient].
mixin McpAdbCmdDelegator {
  McpAdbClient get _adbClient => this as McpAdbClient;

  Future<String> dispatchIntent(
    String serial,
    String action, {
    String? dataUri,
    String? package,
    String? component,
    Map<String, dynamic>? extras,
  }) => McpAdbCmdOps.dispatchIntent(
    _adbClient,
    serial,
    action,
    dataUri: dataUri,
    package: package,
    component: component,
    extras: extras,
  );
  Future<String> getLogcat(
    String serial, {
    String? tag,
    String? level,
    int limit = 50,
    int? pid,
    int? sinceEpochSeconds,
  }) => McpAdbCmdOps.getLogcat(
    _adbClient,
    serial,
    tag: tag,
    level: level,
    limit: limit,
    pid: pid,
    sinceEpochSeconds: sinceEpochSeconds,
  );
  Future<String> checkCrash(String serial, {String? package, int limit = 50}) =>
      McpAdbCmdOps.checkCrash(
        _adbClient,
        serial,
        package: package,
        limit: limit,
      );
  Future<bool> scanMediaFile(String serial, String filePath) =>
      McpAdbCmdOps.scanMediaFile(_adbClient, serial, filePath);
  Future<bool> installApk(
    String serial,
    String apkPath, {
    bool reinstall = true,
    bool grantPermissions = true,
  }) => McpAdbCmdOps.installApk(
    _adbClient,
    serial,
    apkPath,
    reinstall: reinstall,
    grantPermissions: grantPermissions,
  );
  Future<String> shell(String serial, String command) =>
      McpAdbCmdOps.shell(_adbClient, serial, command);
}
