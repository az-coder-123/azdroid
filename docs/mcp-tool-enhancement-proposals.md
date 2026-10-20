# 🤖 Azdroid MCP Server — Tool Enhancement Proposals

> Architectural evaluation and concrete backlog proposals for future MCP tool enhancements (OpenPlayer3 case study).

---

## 📌 1. Executive Summary & Context

During end-to-end testing and automation of the **OpenPlayer3** Android media player using **Azdroid MCP Server**, friction points across text input, gesture timing, and accessibility navigation were identified.

- **Phase 1 (Completed):** Resolved IME autocorrect corruption via `android_set_text` / `android_clear_text` and gesture window constraints via `android_double_tap`.
- **Phase 2 (Completed):** Added precision drag controls via `android_drag`, direct crash diagnostics via `android_check_crash`, and instant media indexing via `android_scan_media_file`.
- **Phase 3 Backlog (Remaining Proposals):** Multi-turn token reduction for accessibility clicks and robust asynchronous UI state synchronization.

---

## 🛠️ 2. Remaining Proposed MCP Tools (Phase 3 Backlog)

### Category: Smart Element Querying & State Synchronization

#### 1. `android_click_by_text` & `android_click_by_desc`
- **Problem:** Currently, clicking a known button requires a multi-turn workflow:
  1. Fetch `android_get_semantic_tree` (dumps output to disk).
  2. Parse/grep the output file for the element ID.
  3. Invoke `android_click_element_by_id`.
- **Proposed Signatures:**
  ```json
  {
    "name": "android_click_by_text",
    "parameters": {
      "text": { "type": "string", "description": "Exact or partial text to match" },
      "exactMatch": { "type": "boolean", "default": false },
      "deviceSerial": { "type": "string" }
    }
  }
  ```
  ```json
  {
    "name": "android_click_by_desc",
    "parameters": {
      "contentDesc": { "type": "string", "description": "Accessibility content description" },
      "exactMatch": { "type": "boolean", "default": false },
      "deviceSerial": { "type": "string" }
    }
  }
  ```
- **Alternative / Unified Implementation:** Enhance the existing `android_click_element` tool with an `exactMatch: boolean` (default `false`) parameter to avoid proliferating tool names while achieving the same 66% turn reduction.
- **Benefit:** Reduces tool execution turns by 66%, cutting LLM token usage and latency.

#### 2. `android_wait_for_element` (Disappear Condition Support)
- **Problem:** Asynchronous UI transitions (e.g., confirmation dialog opening/dismissing, database deletion, loading spinner) cause race conditions where AI takes actions before the UI finishes rendering. While `android_wait_for_element` currently waits for an element to appear, it does not support waiting for an element or spinner to **disappear**.
- **Proposed Enhancement:**
  ```json
  {
    "name": "android_wait_for_element",
    "parameters": {
      "text": { "type": "string", "description": "Target text to match" },
      "resourceId": { "type": "string", "description": "Target resource ID" },
      "contentDesc": { "type": "string", "description": "Target content-desc" },
      "condition": { "type": "string", "enum": ["appear", "disappear"], "default": "appear" },
      "timeoutMs": { "type": "integer", "default": 10000 },
      "pollIntervalMs": { "type": "integer", "default": 500 },
      "deviceSerial": { "type": "string" }
    }
  }
  ```
- **Benefit:** Eliminates test race conditions during asynchronous loading animations and progress spinners.

---

## 📈 3. Backlog Assessment Matrix

| Tool | Impact Area | Primary Benefit | Implementation Complexity | Status |
| :--- | :--- | :--- | :---: | :---: |
| **`android_click_by_desc` / `text`** | Efficiency | Saves 2 tool turns & ~1,500 prompt tokens per click | Medium | ⏳ **Phase 3 (Backlog)** |
| **`android_wait_for_element` (`disappear`)** | Reliability | Eliminates race conditions for loading dialogs & spinners | Medium | ⏳ **Phase 3 (Backlog)** |

> [!NOTE]
> **Completed Enhancements (v1.0.1):** `android_set_text`, `android_clear_text`, `android_double_tap`, `android_drag`, `android_scan_media_file`, `android_check_crash`, and `android_long_press` have been fully implemented, tested, and published across the 58-tool registry. See [MCP Server Guide](features/mcp-ai-agent-server.md) for full documentation.
