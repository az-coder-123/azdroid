# Accessibility UI Tree Pruning & LLM Token Optimization

> **Subsystem:** MCP Server (`lib/features/mcp/domain/services/mcp_semantic_tree_parser.dart`, `mcp_adb_ui_ops.dart`)  
> **Affected Platform:** Android 10+ / Custom OEM ROMs (MIUI, EMUI, ColorOS) / AI Model Context Windows  
> **Severity:** High (AI Agent Blindness & Severe LLM Token Exhaustion)  
> **Resolution Date:** October 2026  

---

## 1. 🔍 Context & Symptoms

Prior to this implementation, AI coding agents and autonomous desktop assistants interacting with Android devices through Azdroid faced two core limitations:
1. **Coordinate & Vision Bottleneck:** AI models relied primarily on coordinate guessing, fuzzy vision inference (`screencap`), or fragile regex pattern matching across raw XML dumps.
2. **Extreme Token Exhaustion:** A standard Android application view hierarchy produced by `uiautomator dump` yields 30KB to 85KB of dense XML containing 200+ deeply nested, non-interactive layout containers (`FrameLayout`, `LinearLayout`, `ViewGroup`, zero-sized spacer views). Feeding raw XML dumps into LLMs consumed 10,000 to 18,000 tokens per action step, triggering massive latency and context window overflow.
3. **Regex Attribute Inversion Crashes:** Android vendors and OS versions (AOSP vs MIUI vs EMUI) emit XML attributes in unpredictable sequences (e.g., `bounds` before `text` or `content-desc` before `resource-id`), causing hardcoded regular expressions to fail silently.

---

## 2. 🔬 Diagnostic Traces & Evidence

When testing `android_find_element` and `android_dump_hierarchy` on real devices (e.g., Xiaomi Redmi 9 on MIUI / Android 10):

1. **Vendor Stderr Interference:**
   ```bash
   adb shell uiautomator dump /data/local/tmp/window_dump.xml
   # Output on MIUI:
   # java.io.FileNotFoundException: /data/system/theme_config/theme_compatibility.xml
   # UI hierchary dumped to: /data/local/tmp/window_dump.xml
   ```
   Checking process exit codes or non-empty stderr caused the parser to reject a completely valid dumped XML file.

2. **Regex Fragility on Custom ROMs:**
   ```dart
   // Fragile flat regex: fails if vendor orders 'resource-id' before 'text'
   RegExp(r'text="([^"]*)"[^>]*resource-id="([^"]*)"[^>]*class="([^"]*)"')
   ```

3. **Token Payload Benchmarks:**
   - Raw XML Dump: ~68,400 bytes (~14,200 tokens).
   - Pruned Semantic Digest: ~1,850 bytes (~320 tokens) — **97.3% token reduction**.

---

## 3. 🧩 Root Cause Analysis

1. **DOM Structure vs Flat Stream:** Android view hierarchies are multi-level hierarchical trees. Flattening XML with regex assumes fixed ordering and fails to respect element nesting or calculate view visibility.
2. **Layout Clutter:** Over 85% of Android nodes on screen are passive spatial containers (`RelativeLayout`, `FrameLayout`, `View`) with no text, no action callbacks, and zero semantic relevance to an AI assistant.
3. **Lack of Grounded Action Target:** Without persistent, indexed references, an LLM must emit floating-point coordinates `(x, y)` which can shift depending on window scaling and display density.

---

## 4. 🏛️ Architectural Solution

Azdroid implemented **Option A: Pure Dart Semantic Tree Pruner & Indexed Digest**:

1. **Strict DOM Parsing with `package:xml`:**
   Replaced regex pattern matching with structured DOM parsing via `XmlDocument.parse()`, making attribute ordering completely irrelevant.
2. **Semantic Pruning Filter (`McpSemanticTreeParser`):**
   - Discards zero-sized (`width <= 0 || height <= 0`) and off-screen views.
   - Retains only elements that are:
     - Interactive (`clickable="true"`, `scrollable="true"`, `checkable="true"`).
     - Informational (non-empty `text` or `content-desc`).
     - Input/Control widgets (`EditText`, `Button`, `Switch`, `CheckBox`, `SeekBar`).
3. **Compact Indexed Digest (`toDigestLine()`):**
   Generates a one-line token-optimized representation with sequential 1-based IDs:
   ```text
   === Screen UI Tree (6 elements) ===
   [#1] TextView text:"Search settings" desc:"Search" clickable:true center:(540,156)
   [#2] RecyclerView scrollable:true center:(540,1290)
   [#3] LinearLayout clickable:true center:(540,360)
   [#4] TextView text:"Network & internet" center:(483,330)
   [#5] TextView text:"Wi-Fi, mobile, hotspot" center:(433,388)
   [#6] Switch desc:"Toggle Airplane" checked:false clickable:true center:(930,360)
   ```
4. **Deterministic Direct-ID Tapping (`android_click_element_by_id`):**
   Caches the pruned elements per device serial. When an AI agent issues `android_click_element_by_id(id: 6)`, the server retrieves the exact element from memory and taps `(930, 360)` in < 50ms without image recognition latency.

---

## 5. ✅ Prevention & Reusability Checklist

- [x] **Never parse XML with flat regex:** Always use `package:xml` or dedicated DOM parsers for protocol and UI data.
- [x] **Filter at the server boundary:** Prune and compress payloads before sending data to LLM context windows to minimize inference cost and latency.
- [x] **Index interactive elements sequentially:** Provide 1-based IDs `[#1]`, `[#2]` so agents can target elements with zero ambiguity.
- [x] **Check payload existence over stderr:** OEM daemons frequently log benign warnings to stderr; verify valid output signatures (`<hierarchy`) rather than failing on stderr strings.
