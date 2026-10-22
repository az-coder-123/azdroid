import 'dart:convert';

import 'package:desk_droid/features/mcp/data/services/mcp_adb_client.dart';
import 'package:desk_droid/features/mcp/data/utils/mcp_argument_helper.dart';
import 'package:desk_droid/features/mcp/domain/entities/mcp_tool_definition.dart';

/// Handler for UI accessibility inspection, element querying, connectivity, and system controls.
class McpSemanticSystemToolExecutor {
  const McpSemanticSystemToolExecutor(this._adb);

  final McpAdbClient _adb;

  bool canHandle(String toolName) {
    return const {
      'android_dump_hierarchy',
      'android_get_semantic_tree',
      'android_click_element_by_id',
      'android_find_element',
      'android_click_element',
      'android_toggle_wifi',
      'android_toggle_airplane_mode',
      'android_grant_permission',
      'android_revoke_permission',
      'android_set_volume',
      'android_wake_screen',
      'android_open_settings',
    }.contains(toolName);
  }

  Future<McpToolResult> execute(
    String toolName,
    String serial,
    Map<String, dynamic> arguments,
  ) async {
    switch (toolName) {
      case 'android_dump_hierarchy':
        final compressed = arguments.getBool('compressed', defaultValue: true);
        final xml = await _adb.dumpHierarchy(serial, compressed: compressed);
        return McpToolResult.text('UI Hierarchy for $serial:\n$xml');

      case 'android_get_semantic_tree':
        final digest = await _adb.getSemanticTree(serial);
        return McpToolResult.text(digest);

      case 'android_click_element_by_id':
        final id = arguments.getRequiredInt('id', aliases: ['elementId']);
        final success = await _adb.clickElementById(serial, id);
        return success
            ? McpToolResult.text(
                'Successfully tapped element [#$id] on $serial.',
              )
            : McpToolResult.error(
                'Failed to tap element [#$id]: not found in active tree.',
              );

      case 'android_find_element':
        final text = arguments.getString('text');
        final resId = arguments.getString('resourceId', aliases: ['id']);
        final desc = arguments.getString('contentDesc', aliases: ['desc']);
        final element = await _adb.findElement(
          serial,
          text: text,
          resourceId: resId,
          contentDesc: desc,
        );
        return element != null
            ? McpToolResult.text(
                'Element Found on $serial:\n${const JsonEncoder.withIndent('  ').convert(element)}',
              )
            : McpToolResult.error(
                'Element matching query not found on screen.',
              );

      case 'android_click_element':
        final text = arguments.getString('text');
        final resId = arguments.getString('resourceId', aliases: ['id']);
        final desc = arguments.getString('contentDesc', aliases: ['desc']);
        final success = await _adb.clickElement(
          serial,
          text: text,
          resourceId: resId,
          contentDesc: desc,
        );
        return success
            ? McpToolResult.text(
                'Clicked element on $serial (Query: ${text ?? resId ?? desc}).',
              )
            : McpToolResult.error(
                'Failed to click element: element not found on screen.',
              );

      case 'android_toggle_wifi':
        final enable = arguments.getBool(
          'enable',
          aliases: ['enabled', 'state'],
          defaultValue: true,
        );
        final success = await _adb.toggleWifi(serial, enable);
        return success
            ? McpToolResult.text(
                'Wi-Fi ${enable ? 'enabled' : 'disabled'} on $serial.',
              )
            : McpToolResult.error('Failed to toggle Wi-Fi on $serial.');

      case 'android_toggle_airplane_mode':
        final enable = arguments.getBool(
          'enable',
          aliases: ['enabled', 'state'],
          defaultValue: true,
        );
        final success = await _adb.toggleAirplaneMode(serial, enable);
        return success
            ? McpToolResult.text(
                'Airplane mode ${enable ? 'enabled' : 'disabled'} on $serial.',
              )
            : McpToolResult.error('Failed to toggle Airplane mode on $serial.');

      case 'android_grant_permission':
        final pkg = arguments.getRequiredString('package', aliases: ['pkg']);
        final perm = arguments.getRequiredString(
          'permission',
          aliases: ['perm'],
        );
        final success = await _adb.grantPermission(serial, pkg, perm);
        return success
            ? McpToolResult.text('Permission $perm granted to $pkg on $serial.')
            : McpToolResult.error('Failed to grant permission $perm to $pkg.');

      case 'android_revoke_permission':
        final pkg = arguments.getRequiredString('package', aliases: ['pkg']);
        final perm = arguments.getRequiredString(
          'permission',
          aliases: ['perm'],
        );
        final success = await _adb.revokePermission(serial, pkg, perm);
        return success
            ? McpToolResult.text(
                'Permission $perm revoked from $pkg on $serial.',
              )
            : McpToolResult.error(
                'Failed to revoke permission $perm from $pkg.',
              );

      case 'android_set_volume':
        final stream = arguments.getInt('stream', defaultValue: 3);
        final vol = arguments.getRequiredInt(
          'volumeIndex',
          aliases: ['volume', 'vol', 'level'],
        );
        final success = await _adb.setVolume(
          serial,
          stream: stream,
          volumeIndex: vol,
        );
        return success
            ? McpToolResult.text(
                'Audio stream $stream volume set to $vol on $serial.',
              )
            : McpToolResult.error('Failed to set volume on $serial.');

      case 'android_wake_screen':
        final wake = arguments.getBool(
          'wake',
          aliases: ['state', 'screenOn', 'enable'],
          defaultValue: true,
        );
        final success = await _adb.wakeOrSleep(serial, wake);
        return success
            ? McpToolResult.text(
                'Device screen ${wake ? 'woken up' : 'put to sleep'} on $serial.',
              )
            : McpToolResult.error('Failed to toggle screen state on $serial.');

      case 'android_open_settings':
        final action = arguments.getString('action');
        final pkg = arguments.getString('package', aliases: ['pkg']);
        final out = await _adb.openSettings(
          serial,
          action: action,
          packageName: pkg,
        );
        return McpToolResult.text('Settings launched on $serial:\n$out');

      default:
        return McpToolResult.error('Unhandled semantic/system tool: $toolName');
    }
  }
}
