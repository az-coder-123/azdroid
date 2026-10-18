# Feature: MCP Live Activity (AI Is Controlling This Device)

> **Subsystem:** writer `lib/features/mcp/data/services/mcp_activity_recorder.dart`; reader `lib/features/mcp_status/`
> **Contract:** `McpActivityEvent` (`lib/core/models/`), `McpActivityPaths` (`lib/core/services/`)
> **Shown in:** the MCP status panel (**Live Activity**) and a banner on the mirroring page
> **Platforms:** macOS ✅ · Windows 🧪 (implemented, not run) ([status](../platform-support.md))

---

## 1. What the User Sees

- **Mirroring page:** a green banner at the top center, *"claude-ai is controlling this device · android_tap"*, while an AI client used that device in the last 10 seconds (`McpStatusConstants.activeWindow`). It does not take clicks.
- **Toolbar tooltip:** *"MCP server: claude-ai is using android_tap on 192.168.1.3:5555"*.
- **Status panel, Live Activity:** each running session (client name, start time, last call) and the 12 newest tool calls across sessions, failures in red.

## 2. Why Files

The MCP server and the app are separate processes, and the server runs even when the app is closed. Each server process writes its own file; the app reads them.

- No network port, firewall prompt, or discovery; works the same on macOS and Windows.
- One writer per file, so there is no locking. A half-written line is skipped by the reader.

## 3. Location and Format

| | Path |
|:---|:---|
| macOS | `~/Library/Application Support/DeskDroid/mcp-activity/<pid>.jsonl` |
| Windows | `%APPDATA%\DeskDroid\mcp-activity\<pid>.jsonl` |

One JSON object per line (`McpActivityEvent.toLine`):

```json
{"kind":"start","at":"2026-10-18T15:33:44.656Z","client":"claude-ai"}
{"kind":"tool","at":"2026-10-18T15:33:45.394Z","tool":"android_get_device_info","device":"192.168.1.3:5555","ok":true,"ms":735}
```

- `client` is `clientInfo.name` from the client's `initialize` request.
- `device` is the serial the tool resolved to (the first connected device when the AI gave none); absent for `android_list_devices`.
- **Privacy:** tool arguments are never written. They may contain text the user asked the AI to type, including passwords.

## 4. Lifecycle

| Event | Who | What |
|:---|:---|:---|
| `initialize` | server | Creates the file with the `start` line |
| Each `tools/call` | server | Appends one `tool` line after the call finishes |
| 500 lines | server | Rewrites the file: `start` line + newest 100 calls |
| File deleted while running | server | Re-creates it with the `start` line on the next call |
| Client disconnects (stdin closes) | server | Deletes the file |
| Server killed (no cleanup) | app | Deletes the file when its PID no longer runs and it is older than 10 minutes |

Write errors never stop the server: they go to stderr (stdout carries the protocol). The app's own `tools/list` handshake sends no `initialize`, so it creates no file.

## 5. Reading in the App

`McpStatusCubit` reads all files every second (`activityPollInterval`) and the process list every 10 seconds. `buildMcpActivitySnapshot` turns the events into sessions (files whose PID runs), recent calls, and `activeByDevice`. A new state is emitted only when this snapshot changes, so the banner appears within about a second and disappears 10 seconds after the last call.

## 6. Limits

- A session started with `dart run` on Windows is not in the process list; its calls still show as recent activity and in the banner, but not as a running session.
- The banner names the client as it reports itself (`claude-ai`, `cursor`), not the app's product name.

## 7. Verification

- Unit: `test/unit/mcp_activity/` (format, writer, reader and pruning, snapshot, server integration).
- Widget: `test/widget/mcp_activity_widgets_test.dart`.
- Device (2026-10-18, Redmi 9): a release `deskdroid-mcp` session wrote `start` + two `tool` lines with `"device":"192.168.1.3:5555"`, deleted the file on disconnect, and the app's repository reported the session and the device as active. The toolbar showed **1** session.
