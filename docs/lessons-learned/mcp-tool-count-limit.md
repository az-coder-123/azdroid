# MCP Clients Cap the Tool Count: Consolidate Behind a Router

## 1. Context & Symptoms

The Azdroid MCP server published 62 tools. Cursor has sent at most about 40 MCP tools, across all servers, to the model and silently dropped the rest (forum reports from 2025; not confirmed for 2026 versions). With Azdroid alone above the cap, an agent in Cursor could lose tools such as `android_click_element` without any error.

Long catalogs cost every client as well: each tool's schema is sent on every request, and near-duplicates (`android_press_key` / `android_press_button`, `android_toggle_wifi` / `android_set_network_condition`) make the model pick the wrong one.

## 2. Diagnostic Traces & Evidence

Groups that differ only in a mode, all already tested on devices:

| Published tool | Former tools (now operations) |
| :--- | :--- |
| `android_tap` (`taps`, `holdMs`) | tap, double_tap, long_press |
| `android_swipe` (`style`, `direction`) | swipe, drag, scroll |
| `android_input_text` (`method`, empty `text`) | set_text, type_text, clear_text |
| `android_press_key` (key name) | press_key, press_button, open_notification_panel |
| `android_get_device_stats` (`kind`) | six `get_*` telemetry tools |
| `android_set_network` (`mode`) | set_network_condition, toggle_wifi, toggle_airplane_mode |

Fifteen such groups brought the catalog to 35.

## 3. Root Cause Analysis

The catalog grew one tool per adb capability. That mirrors the implementation, not how an agent chooses: it decides "tap" first and "how many times" second. Tool count was never checked, so no test noticed when it crossed client limits.

## 4. Architectural Solution

- `McpToolRouter` (`lib/features/mcp/data/handlers/mcp_tool_router.dart`) maps a published tool and its arguments to one executor operation; the device-tested handlers did not change. Conflicting arguments (`taps: 2` with `holdMs`) return an error naming the conflict.
- Names that are not consolidated tools pass through, so the 62 old names keep working for saved prompts and configs.
- `McpToolExecutor.canHandle` requires every operation of a published tool to be routable; the catalog guard test checks that every router entry is published and that the catalog stays at or below `mcpPublishedToolLimit` (36).
- Annotations are per tool, so a merged tool carries the hint of its riskiest operation: `android_set_network` is destructive even for `mode: "normal"`, and `android_clipboard` is not read-only. This trade-off is documented in [../mcp-tool-safety.md](../mcp-tool-safety.md).

Device checks (Redmi 9 on Android 10, Moto g play on Android 13) found three older faults the merge exposed or made riskier: [logcat-buffer-header-lines.md](logcat-buffer-header-lines.md), [input-select-all-unsupported.md](input-select-all-unsupported.md), [text-argument-trimming.md](text-argument-trimming.md).

## 5. Prevention & Reusability Checklist

- [ ] Group tools by the agent's decision (what), with a parameter for the mode (how).
- [ ] Keep a tool-count ceiling in a test, with headroom for the user's other servers.
- [ ] Keep old names routable when renaming or merging; document them as such.
- [ ] Never merge a read-only operation with a destructive one unless the cautious hint is acceptable for both.
- [ ] Read any argument whose value picks a branch exactly as given (no trimming).
