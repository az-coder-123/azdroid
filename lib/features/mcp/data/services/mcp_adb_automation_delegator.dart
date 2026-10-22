part of 'mcp_adb_client.dart';

/// Mixin providing automation, smart waiting, notifications, and button
/// delegator methods for [McpAdbClient].
mixin McpAdbAutomationDelegator {
  McpAdbClient get _adbClient => this as McpAdbClient;

  // --- Automation, Smart Waiting, Notifications & Batching ---
  Future<Map<String, dynamic>?> waitForElement(
    String serial, {
    String? text,
    String? resourceId,
    String? contentDesc,
    int timeoutMs = 10000,
    int pollIntervalMs = 500,
  }) => McpAdbAutomationOps.waitForElement(
    _adbClient,
    serial,
    text: text,
    resourceId: resourceId,
    contentDesc: contentDesc,
    timeoutMs: timeoutMs,
    pollIntervalMs: pollIntervalMs,
  );

  Future<Map<String, dynamic>> waitForCondition(
    String serial, {
    required String condition,
    String? target,
    String? text,
    String? resourceId,
    String? contentDesc,
    int timeoutMs = 10000,
    int pollIntervalMs = 300,
  }) => McpAdbAutomationOps.waitForCondition(
    _adbClient,
    serial,
    condition: condition,
    target: target,
    text: text,
    resourceId: resourceId,
    contentDesc: contentDesc,
    timeoutMs: timeoutMs,
    pollIntervalMs: pollIntervalMs,
  );

  Future<List<Map<String, dynamic>>> batchActions(
    String serial,
    List<Map<String, dynamic>> actions,
  ) => McpAdbBatchOps.batchActions(_adbClient, serial, actions);

  Future<List<Map<String, String>>> getNotifications(
    String serial, {
    String? filter,
  }) => McpAdbNotificationButtonOps.getNotifications(
    _adbClient,
    serial,
    filter: filter,
  );

  Future<bool> snoozeNotification(
    String serial, {
    required String key,
    required Duration hideFor,
  }) => McpAdbNotificationButtonOps.snoozeNotification(
    _adbClient,
    serial,
    key: key,
    hideFor: hideFor,
  );

  Future<void> setLocation(
    String serial, {
    required double latitude,
    required double longitude,
  }) => McpAdbEnvironmentOps.setLocation(
    _adbClient,
    serial,
    latitude: latitude,
    longitude: longitude,
  );

  Future<void> resetLocation(String serial) =>
      McpAdbEnvironmentOps.resetLocation(_adbClient, serial);

  Future<bool> setNetworkCondition(String serial, String mode) =>
      McpAdbEnvironmentOps.setNetworkCondition(_adbClient, serial, mode);

  Future<bool> longPress(
    String serial,
    McpPoint point, {
    int durationMs = 1000,
  }) => McpAdbEnvironmentOps.longPress(
    _adbClient,
    serial,
    point,
    durationMs: durationMs,
  );

  Future<bool> openNotificationPanel(
    String serial, {
    bool expand = true,
    bool quickSettings = false,
  }) => McpAdbNotificationButtonOps.openNotificationPanel(
    _adbClient,
    serial,
    expand: expand,
    quickSettings: quickSettings,
  );

  Future<String> readSharedPreferences(
    String serial, {
    required String package,
    String? fileName,
  }) => McpAdbNotificationButtonOps.readSharedPreferences(
    _adbClient,
    serial,
    package: package,
    fileName: fileName,
  );

  Future<bool> pressButton(String serial, String button) =>
      McpAdbNotificationButtonOps.pressButton(_adbClient, serial, button);
}
