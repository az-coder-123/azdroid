import 'package:desk_droid/core/models/mcp_activity_event.dart';

/// Wording for MCP activity, shared by the panel and the mirroring banner.
class McpActivityLabels {
  const McpActivityLabels._();

  /// The name the AI client reported (`claude-ai`), or a placeholder.
  static String client(String? name) =>
      (name == null || name.isEmpty) ? 'AI client' : name;

  /// Local wall-clock time, `HH:mm:ss`.
  static String time(DateTime at) {
    final local = at.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
  }

  /// `android_tap on 192.168.1.3:5555 · 120 ms` (`· failed` when it failed).
  static String call(McpActivityEvent event) {
    final device = event.deviceSerial;
    return [
      '${event.tool ?? 'tool'}${device == null ? '' : ' on $device'}',
      if (event.durationMs case final ms?) '$ms ms',
      if (event.succeeded == false) 'failed',
    ].join(' · ');
  }
}
