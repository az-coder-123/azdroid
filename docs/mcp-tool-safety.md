# MCP Tool Safety, Coordinates, and Protocol Revision

> How the Azdroid MCP server tells AI clients which tools are risky, how every touch tool reads coordinates, and which MCP revision it speaks. Setup: [mcp-setup-guide.md](mcp-setup-guide.md).

---

## 1. Protocol Revision

The server answers `initialize` with the revision the client asked for when it supports it (`2025-06-18`, `2025-03-26`, `2024-11-05`), otherwise with the newest (`lib/features/mcp/domain/services/mcp_protocol_version.dart`). Tool `annotations` are part of `2025-03-26` and later, so only clients on those revisions rely on them; pinning the server to `2024-11-05` would have hidden them.

The server handles one JSON-RPC message per line and no batches (only `2025-03-26` allowed batches; clients do not send them in practice).

## 2. Tools That Need Confirmation

Twelve tools carry `destructiveHint: true`. The `initialize` instructions (`mcp_server_instructions.dart`) list the same tools, and `test/architecture/mcp_tool_catalog_guard_test.dart` fails when the allowlist changes or a destructive tool is missing from the instructions.

| Risk | Tools |
| :--- | :--- |
| Data loss or reset | `android_clear_app_data`, `android_install_apk`, `android_shell_command`, `android_kill_process`, `android_stop_app`, `android_dismiss_notification`, `android_revoke_permission` (Android kills the app) |
| Overwrites a file | `android_push_file` (on the phone), `android_pull_file` (on the computer) |
| Cuts a Wi-Fi ADB connection | `android_toggle_wifi` (off), `android_toggle_airplane_mode` (on), `android_set_network_condition` (`offline`, `data_only`); use them over USB |

The last two groups and `android_revoke_permission` use `destructiveStateSetToolAnnotations` (`idempotentHint: true`): they set a fixed state or overwrite the same file, so repeating a call changes nothing more. The first call is still the risky one.

## 3. Coordinates

Every touch tool (tap, double tap, long press, swipe, drag, scroll, batch steps) reads points the same way, through `McpPoint` (`lib/features/mcp/data/utils/mcp_point.dart`):

| Given as | Read as |
| :--- | :--- |
| `xRatio`, `xPercent` | Screen fraction, whatever the value |
| `xPixel`, `xPx` | Pixels, whatever the value (`xPixel: 1` is pixel 1) |
| Raw `x` and `y` | Fractions when **both** are within 0.0–1.0, otherwise pixels |
| Raw `x` next to `yPixel`/`yRatio` | Fraction when within 0.0–1.0, otherwise pixels |

Units can be mixed per axis (`xRatio: 0.5, yPixel: 600`). The adb layer only sends pixels and queries the display size only when a fraction needs it. Background: [lessons-learned/coordinate-unit-resolved-once.md](lessons-learned/coordinate-unit-resolved-once.md).

## 4. Text Entry

| Tool | How | Limits |
| :--- | :--- | :--- |
| `android_set_text` | Pastes through the clipboard (replacing it), so IMEs such as Telex cannot alter the text | Without `cmd clipboard` it types ASCII instead and rejects other text; the result says `pasted` or `typed` |
| `android_type_text` | Key events (`input text`); clipboard untouched | ASCII only: Android's `input text` crashes on other characters, so the tool returns an error |

Both send the text to the device shell as one single-quoted word. Before 2026-10-22 it was unquoted: `it's` broke the command and `a; reboot` would have run `reboot`.

## 5. Device Support

`adb shell cmd <service>` exits with code 0 even when the service has no shell command, so the server treats the `No shell command implementation` output as a failure (`McpShellResult`) and returns the reason instead of a false success. Measured 2026-10-22:

| Tool | Needs | Android 10 (Redmi 9) | Android 13 (Moto g play) |
| :--- | :--- | :--- | :--- |
| `get_clipboard`, `set_clipboard`, paste in `set_text` | `cmd clipboard` | ❌ error | ❌ error |
| `simulate_biometric` | emulator (`adb emu finger touch`) | ❌ error | ❌ error |
| `set_location` | `cmd location providers` (Android 12+), location on | ❌ error | ✅ gps, network, fused mocked; `reset` restores |
| `dismiss_notification` | `cmd notification snooze` (Android 11+) | ❌ error | ✅ hidden, back after `hideMinutes` |

Emulators were not measured (the test emulator did not boot on the Intel Mac used).

## 6. Device Selection

With several devices connected and no `deviceSerial`, every tool except `android_list_devices` returns an error listing the serials instead of using the first one.
