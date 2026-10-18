import 'package:desk_droid/features/mcp_status/data/datasources/mcp_client_config_reader.dart';
import 'package:desk_droid/features/mcp_status/domain/entities/mcp_client_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'fake_mcp_file_probe.dart';

void main() {
  const app = '/Applications/DeskDroid.app/Contents/MacOS/deskdroid-mcp';
  const config = '/Users/dev/.cursor/mcp.json';
  const client = (name: 'Cursor', configPath: config);

  Future<McpClientStatus> readWith(FakeMcpFileProbe files) =>
      McpClientConfigReader(
        expectedExecutable: app,
        pathContext: p.posix,
        files: files,
      ).read(client);

  Future<McpClientStatus> readJson(String json) =>
      readWith(FakeMcpFileProbe(files: {config: json}));

  test('an entry launching this app is configured, whatever its key', () async {
    final status = await readJson(
      '{"mcpServers":{"phone":{"command":"$app"}}}',
    );
    expect(status.setup, McpClientSetup.configured);
    expect(status.configuredCommand, app);
  });

  test('another copy or a source checkout is configured elsewhere', () async {
    final copy = await readJson(
      '{"mcpServers":{"d":{"command":"/Users/dev/Downloads/DeskDroid.app/Contents/MacOS/deskdroid-mcp"}}}',
    );
    final source = await readJson(
      '{"mcpServers":{"d":{"command":"dart","args":["run","/src/bin/deskdroid_mcp.dart"]}}}',
    );
    final script = await readJson(
      '{"mcpServers":{"d":{"command":"/src/scripts/start_mcp_server.sh"}}}',
    );
    for (final s in [copy, source, script]) {
      expect(s.setup, McpClientSetup.configuredElsewhere);
    }
    expect(source.configuredCommand, 'dart run /src/bin/deskdroid_mcp.dart');
  });

  test('other servers only, or no mcpServers, is not configured', () async {
    expect(
      (await readJson('{"mcpServers":{"git":{"command":"uvx"}}}')).setup,
      McpClientSetup.notConfigured,
    );
    expect(
      (await readJson('{"preferences":{}}')).setup,
      McpClientSetup.notConfigured,
    );
  });

  test(
    'a missing file is not configured when the client folder exists',
    () async {
      expect(
        (await readWith(FakeMcpFileProbe(directories: {'/Users/dev/.cursor'})))
            .setup,
        McpClientSetup.notConfigured,
      );
      expect(
        (await readWith(FakeMcpFileProbe())).setup,
        McpClientSetup.clientNotFound,
      );
    },
  );

  test('invalid JSON or an unreadable file is reported, not thrown', () async {
    expect((await readJson('{not json')).setup, McpClientSetup.unreadable);
    expect(
      (await readWith(FakeMcpFileProbe(files: {config: null}))).setup,
      McpClientSetup.unreadable,
    );
  });

  test('Windows paths compare without case', () async {
    const winApp = r'C:\Apps\DeskDroid\deskdroid-mcp.exe';
    const winConfig = r'C:\Users\dev\.cursor\mcp.json';
    final status = await McpClientConfigReader(
      expectedExecutable: winApp,
      pathContext: p.windows,
      files: FakeMcpFileProbe(
        files: {
          winConfig: r'{"mcpServers":{"d":{"command":"c:\\apps\\deskdroid\\DESKDROID-MCP.EXE"}}}',
        },
      ),
    ).read((name: 'Cursor', configPath: winConfig));
    expect(status.setup, McpClientSetup.configured);
  });
}
