import 'package:desk_droid/features/mcp/data/services/mcp_adb_client.dart';
import 'package:desk_droid/features/mcp/domain/entities/mcp_tool_definition.dart';

/// Handler for application lifecycle, package querying, clipboard, and file transfer tools.
class McpAppDeviceToolExecutor {
  const McpAppDeviceToolExecutor(this._adb);

  final McpAdbClient _adb;

  bool canHandle(String toolName) {
    return const {
      'android_get_current_app',
      'android_launch_app',
      'android_stop_app',
      'android_clear_app_data',
      'android_list_packages',
      'android_get_clipboard',
      'android_set_clipboard',
      'android_get_device_info',
      'android_push_file',
      'android_pull_file',
    }.contains(toolName);
  }

  Future<McpToolResult> execute(
    String toolName,
    String serial,
    Map<String, dynamic> arguments,
  ) async {
    switch (toolName) {
      case 'android_get_current_app':
        final appInfo = await _adb.getCurrentApp(serial);
        return appInfo != null
            ? McpToolResult.text(
                'Active Foreground App on $serial:\nPackage: ${appInfo['package']}\nActivity: ${appInfo['activity']}',
              )
            : McpToolResult.error(
                'Unable to detect active foreground application.',
              );

      case 'android_launch_app':
        final pkg = arguments['package'] as String;
        final success = await _adb.launchApp(serial, pkg);
        return success
            ? McpToolResult.text('Application $pkg launched on $serial.')
            : McpToolResult.error('Failed to launch application $pkg.');

      case 'android_stop_app':
        final pkg = arguments['package'] as String;
        final success = await _adb.stopApp(serial, pkg);
        return success
            ? McpToolResult.text('Application $pkg force-stopped on $serial.')
            : McpToolResult.error('Failed to stop application $pkg.');

      case 'android_clear_app_data':
        final pkg = arguments['package'] as String;
        final success = await _adb.clearAppData(serial, pkg);
        return success
            ? McpToolResult.text(
                'Application data and cache cleared for $pkg on $serial.',
              )
            : McpToolResult.error('Failed to clear app data for $pkg.');

      case 'android_list_packages':
        final thirdParty = arguments['thirdPartyOnly'] as bool? ?? true;
        final query = arguments['query'] as String?;
        final pkgs = await _adb.listPackages(
          serial,
          thirdPartyOnly: thirdParty,
          query: query,
        );
        return McpToolResult.text(
          'Installed Packages (${pkgs.length}):\n${pkgs.join('\n')}',
        );

      case 'android_get_clipboard':
        final content = await _adb.getClipboard(serial);
        return McpToolResult.text('Android Clipboard Content:\n$content');

      case 'android_set_clipboard':
        final text = arguments['text'] as String;
        final success = await _adb.setClipboard(serial, text);
        return success
            ? McpToolResult.text('Text copied to Android clipboard on $serial.')
            : McpToolResult.error('Failed to set Android clipboard.');

      case 'android_get_device_info':
        final info = await _adb.getDeviceInfo(serial);
        final buffer = StringBuffer('Device Information for $serial:\n');
        info.forEach((k, v) => buffer.writeln('• $k: $v'));
        return McpToolResult.text(buffer.toString().trim());

      case 'android_push_file':
        final local = arguments['localPath'] as String;
        final remote = arguments['remotePath'] as String;
        final success = await _adb.pushFile(serial, local, remote);
        return success
            ? McpToolResult.text('File uploaded: $local -> $remote on $serial.')
            : McpToolResult.error('Failed to push file $local to $remote.');

      case 'android_pull_file':
        final remote = arguments['remotePath'] as String;
        final local = arguments['localPath'] as String;
        final success = await _adb.pullFile(serial, remote, local);
        return success
            ? McpToolResult.text(
                'File downloaded: $remote -> $local from $serial.',
              )
            : McpToolResult.error('Failed to pull file $remote to $local.');

      default:
        return McpToolResult.error('Unhandled app/device tool: $toolName');
    }
  }
}
