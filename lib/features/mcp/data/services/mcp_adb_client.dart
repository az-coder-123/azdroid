import 'dart:io';
import 'dart:math';

import 'package:desk_droid/core/extensions/line_split_extension.dart';
import 'package:desk_droid/core/services/adb_binary_locator.dart';
import 'package:desk_droid/core/services/process_output_encoding.dart';
import 'package:desk_droid/features/control/data/datasources/control_datasource.dart';
import 'package:desk_droid/features/control/data/datasources/scrcpy_control_datasource.dart';
import 'package:desk_droid/features/control/domain/entities/frame_size.dart';
import 'package:desk_droid/features/control/domain/entities/touch_stream.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_ocr_fallback_ops.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_shell_result.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_text_entry.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_unsupported_exception.dart';
import 'package:desk_droid/features/mcp/data/utils/mcp_point.dart';
import 'package:desk_droid/features/mcp/data/utils/mcp_point_arguments.dart';
import 'package:desk_droid/features/mcp/data/utils/mcp_scroll_path.dart';
import 'package:desk_droid/features/mcp/domain/entities/mcp_semantic_element.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_foreground_app_parser.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_semantic_tree_parser.dart';
import 'package:get_it/get_it.dart';

part 'mcp_adb_app_ops.dart';
part 'mcp_adb_automation_delegator.dart';
part 'mcp_adb_automation_ops.dart';
part 'mcp_adb_batch_compiler.dart';
part 'mcp_adb_batch_ops.dart';
part 'mcp_adb_cmd_ops.dart';
part 'mcp_adb_device_ops.dart';
part 'mcp_adb_environment_ops.dart';
part 'mcp_adb_gesture_ops.dart';
part 'mcp_adb_input_ops.dart';
part 'mcp_adb_media_proc_ops.dart';
part 'mcp_adb_notification_button_ops.dart';
part 'mcp_adb_performance_ops.dart';
part 'mcp_adb_resolver.dart';
part 'mcp_adb_system_delegator.dart';
part 'mcp_adb_system_ops.dart';
part 'mcp_adb_text_ops.dart';
part 'mcp_adb_ui_ops.dart';

/// Pure Dart ADB client for Azdroid MCP Server.
/// Operates without UI or Flutter framework dependencies.
class McpAdbClient with McpAdbSystemDelegator, McpAdbAutomationDelegator {
  McpAdbClient({String? explicitAdbPath}) : _cachedAdbPath = explicitAdbPath;

  String? _cachedAdbPath;

  Future<String?> resolveAdb() async =>
      _cachedAdbPath = await McpAdbResolver.resolve(_cachedAdbPath);

  Future<ProcessResult> run(List<String> args) async {
    final adb = await resolveAdb();
    if (adb == null) {
      throw const SocketException('ADB executable not found on host machine.');
    }
    return await Process.run(
      adb,
      args,
      stdoutEncoding: adbOutputEncoding,
      stderrEncoding: adbOutputEncoding,
    );
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
  Future<bool> tap(String serial, McpPoint point) =>
      McpAdbInputOps.tap(this, serial, point);
  Future<(bool ok, bool stateChanged)> tapAndVerify(
    String serial,
    McpPoint point, {
    int delayMs = 300,
  }) => McpAdbInputOps.tapAndVerify(this, serial, point, delayMs: delayMs);
  Future<bool> swipe(
    String serial,
    McpPoint start,
    McpPoint end,
    int durationMs,
  ) => McpAdbInputOps.swipe(this, serial, start, end, durationMs);
  Future<bool> typeText(String serial, String text) =>
      McpAdbTextOps.typeText(this, serial, text);
  Future<bool> pressKey(String serial, int keyCode) =>
      McpAdbTextOps.pressKey(this, serial, keyCode);
  Future<bool> doubleTap(
    String serial,
    McpPoint point, {
    int intervalMs = 120,
  }) => McpAdbInputOps.doubleTap(this, serial, point, intervalMs: intervalMs);
  Future<McpTextEntry> setText(
    String serial,
    String text, {
    int? elementId,
    bool clearFirst = false,
  }) => McpAdbTextOps.setText(
    this,
    serial,
    text,
    elementId: elementId,
    clearFirst: clearFirst,
  );
  Future<bool> clearText(String serial, {int? elementId}) =>
      McpAdbTextOps.clearText(this, serial, elementId: elementId);
  Future<bool> drag(
    String serial,
    McpPoint start,
    McpPoint end, {
    int durationMs = 1000,
  }) => McpAdbInputOps.drag(this, serial, start, end, durationMs: durationMs);
  Future<bool> pinchGesture(
    String serial, {
    required double scale,
    double centerX = 0.5,
    double centerY = 0.5,
    int durationMs = 400,
  }) => McpAdbGestureOps.pinchGesture(
    this,
    serial,
    scale: scale,
    centerX: centerX,
    centerY: centerY,
    durationMs: durationMs,
  );
  Future<bool> rotateGesture(
    String serial, {
    required double angleDegrees,
    double centerX = 0.5,
    double centerY = 0.5,
    double radius = 200,
    int durationMs = 400,
  }) => McpAdbGestureOps.rotateGesture(
    this,
    serial,
    angleDegrees: angleDegrees,
    centerX: centerX,
    centerY: centerY,
    radius: radius,
    durationMs: durationMs,
  );
  Future<bool> scroll(
    String serial, {
    String direction = 'down',
    double distance = 0.6,
    String speed = 'normal',
    McpPoint? start,
    McpPoint? end,
    int? durationMs,
  }) => McpAdbInputOps.scroll(
    this,
    serial,
    direction: direction,
    distance: distance,
    speed: speed,
    start: start,
    end: end,
    durationMs: durationMs,
  );

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
  Future<String> getLogcat(
    String serial, {
    String? tag,
    String? level,
    int limit = 50,
  }) => McpAdbCmdOps.getLogcat(
    this,
    serial,
    tag: tag,
    level: level,
    limit: limit,
  );
  Future<String> checkCrash(String serial, {String? package, int limit = 50}) =>
      McpAdbCmdOps.checkCrash(this, serial, package: package, limit: limit);
  Future<bool> scanMediaFile(String serial, String filePath) =>
      McpAdbCmdOps.scanMediaFile(this, serial, filePath);
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
    bool thirdPartyOnly = false,
    String? query,
  }) => McpAdbAppOps.listPackages(
    this,
    serial,
    thirdPartyOnly: thirdPartyOnly,
    query: query,
  );

  // --- Telemetry, Clipboard & File Transfers ---
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
}
