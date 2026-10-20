# Engineering Lesson: Large File SRP Decomposition via Mixins & Part Files

## 1. Context & Symptoms
As Azdroid expanded to support 58 headless MCP automation tools and an enterprise-grade logcat console, several core service and presentation files grew beyond the strict 250-line Single Responsibility Principle (SRP) limit defined in `AGENTS.md`:
- `McpAdbClient` (358 lines) and `McpAdbAutomationOps` (296 lines) accumulated device queries, gesture injection, semantic UI inspection, and macro automation.
- `DeviceLogCubit` (344 lines) combined real-time stream ingestion, buffer bounding, viewport presentation toggles, disk persistence, and 10+ log filter/bookmarking actions.
- `ApkInstallerDialog`, `LogDetailDrawer`, and `CropSelectionOverlay` mixed complex layouts with action footers and floating toolbars.

The primary architectural challenge was refactoring these large monolithic classes into compact, decoupled units (< 250 lines) **without breaking unit tests, mocktail interfaces (`Mock implements McpAdbClient`), or stream reactivity**.

---

## 2. Diagnostic Traces & Evidence
1. **Mocktail Interface Preservation:**
   Unit tests (`test/unit/mcp_tool_executor_test.dart`) declare:
   ```dart
   class MockMcpAdbClient extends Mock implements McpAdbClient {}
   ```
   Dart extension methods (`extension Foo on McpAdbClient`) are resolved statically and cannot be intercepted by `Mock.noSuchMethod()`. Converting client delegations to extensions would break test stubbing (`when(() => mockAdb.tap(...))`).

2. **Cubit State Coupling:**
   In `DeviceLogCubit`, filter criteria methods mutated `DeviceLogStreaming.filter` and emitted new states. Extracting them into standalone services would have required passing callbacks or wrapping the Cubit, increasing indirection.

---

## 3. Root Cause Analysis
- **Monolithic Accumulation:** As new MCP tools and logcat filtering options were incrementally added, forwarder methods were appended to existing central classes instead of domain-specific mixins or helper files.
- **Dart Inheritance Model:** Unlike partial classes in C#, Dart requires explicit language constructs (`part`/`part of`, `mixin`, or composition) to break up a single logical class while preserving its implicit type interface.

---

## 4. Architectural Solution

### A. Mixin-Based Class Decomposition for `McpAdbClient`
We decomposed `McpAdbClient` using Dart `mixin` and `part of` directives:
- `mcp_adb_system_delegator.dart`: Mixin providing UI inspection, system settings, telemetry, and media recording delegations (105 lines).
- `mcp_adb_automation_delegator.dart`: Mixin providing smart waiting, batching, notifications, preferences, and hardware key delegations (95 lines).
- `mcp_adb_client.dart`: Retained core process execution, device enumeration, and input gestures (175 lines).
- `class McpAdbClient with McpAdbSystemDelegator, McpAdbAutomationDelegator`: All methods remain part of `McpAdbClient`'s implicit interface, maintaining 100% compatibility with `Mock implements McpAdbClient`.

### B. Split of Automation Operations
Split `mcp_adb_automation_ops.dart` (296 lines) into:
- `mcp_adb_automation_ops.dart` (150 lines): Smart Waiting, Batch Actions, Mock Location, Network Conditioning.
- `mcp_adb_notification_button_ops.dart` (137 lines): Dumpsys notifications, notification panel control, shared preferences, and hardware button simulation.

### C. Mixin Decomposition for `DeviceLogCubit`
We factored presentation concerns out of `DeviceLogCubit` (344 lines) into two focused mixins on `Cubit<DeviceLogState>`:
- `DeviceLogFilterMixin` (95 lines): Bookmark toggling, search query updates, regex/case sensitivity, tag exclusion, and log level filtering.
- `DeviceLogPersistenceMixin` (90 lines): In-memory/device buffer clearing, background file recording, and disk export.
- `DeviceLogCubit` (172 lines): Pure stream subscription, buffer truncation, and viewport pause/scroll control.

### D. Widget Layout Modularization
- `crop_selection_overlay.dart` (248 lines): Extracted positioned floating toolbar wrapper into `crop_floating_toolbar.dart` (48 lines).
- `log_detail_drawer.dart` (130 lines): Extracted inspector header into `log_detail_drawer_header.dart` (176 lines).
- `apk_installer_dialog.dart` (244 lines): Extracted action button bar into `apk_installer_footer.dart` (71 lines).

---

## 5. Prevention & Reusability Checklist
- [x] **File Line Limits:** Every file in `lib/` must remain strictly `< 250 lines`.
- [x] **Mock Compatibility:** When decomposing classes used with `mocktail` or `mockito`, use `mixin` rather than `extension` so all methods remain part of the implicit interface.
- [x] **Zero Warnings:** Run `flutter analyze` and resolve all deprecations and lint hints.
- [x] **100% Test Coverage:** Execute `flutter test` across all 410+ tests before and after refactoring.
- [x] **Single Responsibility:** Isolate presentation widgets, filter criteria, and background process management into independent files.
