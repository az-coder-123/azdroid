# Engineering Lessons Learned & Technical Post-Mortems

> A curated repository of real-world edge cases, operating system quirks, networking anomalies, and reusable architectural solutions discovered during DeskDroid development.

---

## 🎯 Purpose & Philosophy

As an advanced desktop mirroring and remote control utility bridging macOS and Android, DeskDroid interfaces directly with low-level kernel routing, daemon socket lifetimes, USB/Wi-Fi switching, and device permissions.

Whenever an intricate bug, OS-level anomaly, or non-obvious platform behavior is diagnosed and resolved, it must be documented here to:
1. **Prevent Regressions:** Ensure future development does not inadvertently reintroduce known antipatterns.
2. **Accelerate Troubleshooting:** Provide immediate diagnostic workflows for similar future issues.
3. **Share Reusable Patterns:** Formalize resilient architectural patterns (e.g., self-healing daemons, non-destructive parsing).

---

## 📚 Documented Case Studies

| Topic | Primary Subsystem | Key Takeaway / Reusable Solution | Document |
|:---|:---|:---|:---|
| **Mobile Hotspot ADB Routing** | Networking & ADB Daemon | Auto-heal stale macOS socket routing (`No route to host`) by recycling ADB daemon. | [mobile-hotspot-adb-routing.md](mobile-hotspot-adb-routing.md) |
| **Physical MicroSD & Permissions** | Android Filesystem & ADB | Handle `.android_secure` exit code 1 without discarding valid stdout files. | [physical-sdcard-android-secure.md](physical-sdcard-android-secure.md) |
| **macOS App Sandbox Process Execution** | macOS Security & Entitlements | Grant sandbox child-process and network socket entitlements to prevent `EPERM` crashes. | [macos-app-sandbox-process-execution.md](macos-app-sandbox-process-execution.md) |
| **Scrcpy Protocol Packet Framing** | Video Pipeline & VideoToolbox | Parse 12-byte headers (PTS + size) and extract SPS/PPS to avoid `kVTVideoDecoderBadDataErr (-12909)`. | [scrcpy-protocol-packet-framing.md](scrcpy-protocol-packet-framing.md) |
| **Android Screenrecord Clean Finalization** | Android Media & UNIX Signals | Send `SIGINT` (kill -2) and poll process exit to ensure MP4 `moov` atom is properly written. | [android-screenrecord-clean-finalization.md](android-screenrecord-clean-finalization.md) |
| **Xiaomi MIUI Input Security Restrictions** | OEM Security & IME Injection | Guide users to enable USB Security Settings and fallback to clipboard broadcast for Unicode text. | [xiaomi-miui-input-security-restrictions.md](xiaomi-miui-input-security-restrictions.md) |
| **Dual-Connection Device Deduplication** | Device Discovery & Topology | Unify physical USB and Wi-Fi endpoints under single hardware identity using `ro.serialno`. | [dual-connection-device-deduplication.md](dual-connection-device-deduplication.md) |
| **Background Polling UI Churn Prevention** | Flutter UI & BLoC Boundaries | Prevent spinner flashes and focus loss during background scans using `silent: true` and `buildWhen`. | [background-polling-ui-churn-prevention.md](background-polling-ui-churn-prevention.md) |
| **Malformed UTF-8 in Logcat Streams** | Android Streams & Decoding | Use `Utf8Decoder(allowMalformed: true)` to prevent crash on non-UTF-8 driver binary dumps. | [logcat-stream-malformed-utf8-bytes.md](logcat-stream-malformed-utf8-bytes.md) |
| **Multi-Device Subnet Discovery** | Device Discovery & Socket Probing | Sweep full subnet without early break and tune socket timeouts for Wi-Fi power-save latency. | [multi-device-subnet-discovery.md](multi-device-subnet-discovery.md) |
| **Android adbd Port Lifecycle** | Android OS Security & TCP Lifecycle | Understand ephemeral TCP lifetimes and implement zero-click USB-to-Wi-Fi auto-provisioning. | [android-adbd-tcpip-port-lifecycle.md](android-adbd-tcpip-port-lifecycle.md) |
| **Logcat Soft-Wrap Sliver Jank** | Flutter Layout & Virtualized Slivers | Eliminate 10s UI freeze on dynamic extents via adaptive reverse sliver and bounded row lines. | [logcat-soft-wrap-sliver-layout-jank.md](logcat-soft-wrap-sliver-layout-jank.md) |
| **Action Footer RenderFlex Overflow** | UI Layout & Universal Responsiveness | Eliminate horizontal overflow via adaptive `LayoutBuilder`, scrollable `ConstrainedBox`, and dynamic badges. | [renderflex-overflow-action-footer-resilience.md](renderflex-overflow-action-footer-resilience.md) |
| **Accessibility Tree Semantic Pruning** | MCP Server & AI Agent Grounding | Prune 97% of redundant layout nodes and assign sequential [#ID] tags for deterministic click actions. | [accessibility-tree-semantic-pruning.md](accessibility-tree-semantic-pruning.md) |
| **IME Predictive Text & Gesture Latency** | Android IME & MCP Execution | Bypass Telex/IME corruption via atomic clipboard paste and chain double-tap to beat IPC latency. | [ime-predictive-text-and-gesture-latency.md](ime-predictive-text-and-gesture-latency.md) |
| **Large File SRP Mixin Decomposition** | Architecture & SOLID / Clean Code | Decompose monolithic clients & cubits (< 250 lines) via mixins preserving mock interfaces and reactivity. | [large-file-srp-mixin-decomposition.md](large-file-srp-mixin-decomposition.md) |
| **build-tools Lexicographic Version Sort** | Android SDK Tooling & APK Inspection | Compare dotted versions numerically so `34.0.0` beats `9.0.0` when picking `aapt2`. | [build-tools-lexicographic-version-sort.md](build-tools-lexicographic-version-sort.md) |
| **Silent Catch Masked Defects** | Error Handling & Test Reliability | Replace `catch (_) {}` with typed handlers, `tryRead<T>()`, and lints to expose hidden bugs. | [silent-catch-masked-defects.md](silent-catch-masked-defects.md) |
| **Staged Rename Leaked Into Commit** | Git Workflow & Commit Hygiene | Check `git diff --cached` per commit and analyze every commit of a split series in a worktree. | [git-staged-rename-leaked-into-commit.md](git-staged-rename-leaked-into-commit.md) |
| **Bulk Replacement Semantic Drift** | Refactoring Workflow | Audit value-based bulk replacements by call context; equal numbers do not imply equal meaning. | [bulk-replacement-semantic-drift.md](bulk-replacement-semantic-drift.md) |
| **ParallelWaitError Catch Typing** | Dart Async & Error Handling | Generic `on` clauses can silently never match; let each parallel future return its own result. | [dart-parallel-wait-error-typing.md](dart-parallel-wait-error-typing.md) |
| **macOS systemTemp Is Not /tmp** | Host Paths & Diagnostics | `Directory.systemTemp` is `$TMPDIR` on macOS; pin per-OS paths in tests before centralizing. | [macos-systemtemp-is-not-tmp.md](macos-systemtemp-is-not-tmp.md) |
| **Windows Command Output Differences** | Cross-Platform Parsing | Use `splitLines()`, take the first `where` match, and parse ARP output format-agnostically. | [windows-command-output-differences.md](windows-command-output-differences.md) |
| **Foreign-OS Paths in Host Tests** | Cross-Platform Testing | Test foreign path construction as strings; touch disk only with the host path style. | [foreign-os-paths-in-host-tests.md](foreign-os-paths-in-host-tests.md) |
| **Host-Dependent Test Expectations** | Cross-Platform Testing | Inject relative paths and derive OS-specific labels from production sources so tests pass on any runner. | [host-dependent-test-expectations.md](host-dependent-test-expectations.md) |
| **Plugin Registrants Ship With Dependency** | Flutter Tooling & Commit Hygiene | Commit regenerated `macos/`, `windows/`, `linux/`, `ios/` plugin files with the `pubspec` change; tests won't catch their absence. | [plugin-registrants-ship-with-dependency.md](plugin-registrants-ship-with-dependency.md) |

---

## 📐 Authoring Standard for New Lessons

Every new case study added to this directory must adhere strictly to the following standards:

1. **Strict Single Responsibility Principle (SRP):**
   - Each file must cover exactly **one** distinct issue or failure scenario.
   - Keep the file compact and readable (< 250 lines).
2. **Mandatory 5-Section Structure:**
   - **1. Context & Symptoms:** What failed? Exact error messages, error codes, and observable UI state.
   - **2. Diagnostic Traces & Evidence:** Exact terminal commands, log snippets (`deskdroid_dart.log`), and reproduction steps.
   - **3. Root Cause Analysis:** Deep technical explanation of why the failure occurred (OS kernel, networking, daemon state, etc.).
   - **4. Architectural Solution:** How it was resolved in code, design patterns used, and code references.
   - **5. Prevention & Reusability Checklist:** Rules of thumb for engineers to reuse or avoid in other features.
3. **Professional Language:**
   - Written exclusively in professional, concise, and plain English.
