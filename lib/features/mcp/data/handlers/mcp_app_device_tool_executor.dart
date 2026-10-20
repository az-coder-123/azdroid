import 'package:desk_droid/features/mcp/data/services/mcp_adb_client.dart';
import 'package:desk_droid/features/mcp/data/utils/mcp_argument_helper.dart';
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
        if (appInfo == null) {
          return McpToolResult.error(
            'Unable to detect active foreground application.',
          );
        }
        final overlay = appInfo['overlay'];
        return McpToolResult.text(
          'Active Foreground App on $serial:\n'
          'Package: ${appInfo['package']}\n'
          'Activity: ${appInfo['activity']}'
          '${overlay == null ? '' : '\nNote: the system window "$overlay" is in front of it (lock screen or notification shade); unlock or close it before tapping the app.'}',
        );

      case 'android_launch_app':
        final pkg = arguments.getRequiredString(
          'package',
          aliases: ['pkg', 'packageName', 'app'],
        );
        final success = await _adb.launchApp(serial, pkg);
        return success
            ? McpToolResult.text('Application $pkg launched on $serial.')
            : McpToolResult.error('Failed to launch application $pkg.');

      case 'android_stop_app':
        final pkg = arguments.getRequiredString(
          'package',
          aliases: ['pkg', 'packageName', 'app'],
        );
        final success = await _adb.stopApp(serial, pkg);
        return success
            ? McpToolResult.text('Application $pkg force-stopped on $serial.')
            : McpToolResult.error('Failed to stop application $pkg.');

      case 'android_clear_app_data':
        final pkg = arguments.getRequiredString(
          'package',
          aliases: ['pkg', 'packageName', 'app'],
        );
        final success = await _adb.clearAppData(serial, pkg);
        return success
            ? McpToolResult.text(
                'Application data and cache cleared for $pkg on $serial.',
              )
            : McpToolResult.error('Failed to clear app data for $pkg.');

      case 'android_list_packages':
        final thirdParty = arguments.getBool(
          'thirdPartyOnly',
          aliases: ['thirdParty'],
          defaultValue: true,
        );
        final query = arguments.getString(
          'query',
          aliases: ['filter', 'search'],
        );
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
        final text = arguments.getRequiredString(
          'text',
          aliases: ['content', 'value'],
        );
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
        final local = arguments.getRequiredString(
          'localPath',
          aliases: ['path', 'filePath', 'sourcePath', 'local'],
        );
        final remote = arguments.getRequiredString(
          'remotePath',
          aliases: ['targetPath', 'destPath', 'destination', 'remote'],
        );
        final success = await _adb.pushFile(serial, local, remote);
        return success
            ? McpToolResult.text('File uploaded: $local -> $remote on $serial.')
            : McpToolResult.error('Failed to push file $local to $remote.');

      case 'android_pull_file':
        final remote = arguments.getRequiredString(
          'remotePath',
          aliases: ['targetPath', 'sourcePath', 'remote'],
        );
        final local = arguments.getRequiredString(
          'localPath',
          aliases: ['path', 'filePath', 'destPath', 'local'],
        );
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
