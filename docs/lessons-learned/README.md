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
| **Shared adb Transport Stall** | ADB Forwarding & Control Socket | Read every adb-forwarded socket until close; an unread video socket stalls control on the same device. | [adb-forward-shared-transport-stall.md](adb-forward-shared-transport-stall.md) |
| **scrcpy Control Handshake Order** | Video Pipeline & Control Socket | Open control after the dummy byte and before the header, signaled by the `connected` state. | [scrcpy-control-socket-handshake-order.md](scrcpy-control-socket-handshake-order.md) |
| **Touch Mapping Wrong Frame Size** | Input Control & Coordinate Mapping | Map touches with the live video frame size; never default a device resolution. | [touch-mapping-wrong-frame-size.md](touch-mapping-wrong-frame-size.md) |
| **Layout Math Assumed Widget Width** | UI Layout & Universal Responsiveness | Let `Expanded` absorb leftover space instead of hard-coding a neighbor's width; it changes with visual density. | [layout-math-assumed-widget-width.md](layout-math-assumed-widget-width.md) |
| **scrcpy Cleanup Restore Ordering** | Device Settings & Server Lifecycle | Use `cleanup=true` to restore changed settings, wait for the old restore process before restarting, prefer finite values; v5 `keep_active` changes no setting, but the waiter still orders display-power restores. | [scrcpy-cleanup-restore-ordering.md](scrcpy-cleanup-restore-ordering.md) |
| **Unwired Setting Silent No-Op** | Settings & Data Flow | Make option parameters required at the boundary and test their effect there; a default hid that `stayAwake` reached nothing. | [unwired-setting-silent-no-op.md](unwired-setting-silent-no-op.md) |
| **Screen Off Pressed POWER** | Device Power & Control Socket | Use scrcpy `SET_DISPLAY_POWER` to darken the panel while awake; POWER sleeps the phone and freezes the mirror. | [screen-off-power-key-slept-device.md](screen-off-power-key-slept-device.md) |
| **Documented Shortcut Not Wired** | Keyboard Shortcuts & Feature Boundaries | Let unhandled shortcuts bubble to the owning feature's `CallbackShortcuts`, and test every documented combination. | [documented-shortcut-not-wired.md](documented-shortcut-not-wired.md) |
| **Socket Destroy Drops Queued Writes** | Sockets & Session Shutdown | `flush()` (bounded) before `destroy()` when the last message must arrive; test with payloads larger than the buffer. | [socket-destroy-drops-queued-writes.md](socket-destroy-drops-queued-writes.md) |
| **Remote Unlock Misdiagnosis** | Device Testing & Diagnosis | Blame the step the stack trace names; re-check a limitation before documenting it; never store a PIN. | [remote-unlock-misdiagnosis.md](remote-unlock-misdiagnosis.md) |
| **scrcpy Audio Socket Order** | Audio Pipeline & Protocol | Audio is the second socket of the session (video, audio, control); decide `audio=` before starting the server. | [scrcpy-audio-socket-order.md](scrcpy-audio-socket-order.md) |
| **Jitter Buffer Latency Floor** | Audio Pipeline & Buffering | A cap does not pull latency down; trim the minimum fill over a window back to the target. | [jitter-buffer-latency-floor.md](jitter-buffer-latency-floor.md) |
| **Real-Time Audio Callback Allocation** | macOS Audio & Real-Time Threads | No heap allocation in a render callback; use stack scratch and preallocated buffers. | [realtime-audio-callback-allocation.md](realtime-audio-callback-allocation.md) |
| **Stale Reader Thread Shared State** | Native Threads & Session Lifecycle | One object per connection with its own stop flag; the reading thread closes its socket. | [stale-reader-thread-shared-state.md](stale-reader-thread-shared-state.md) |
| **Duplicate Navigation Input Paths** | Input Control & Feature Boundaries | Buttons, shortcuts, and gestures dispatch one event; remove the old path when upgrading it. | [duplicate-navigation-input-paths.md](duplicate-navigation-input-paths.md) |
| **Docs Claims Without Code** | Documentation & Product Truth | Tie every documented capability to the code that provides it; delete placeholder models. | [docs-claims-without-code.md](docs-claims-without-code.md) |
| **Trackpad PanZoom Scroll Lost** | Input Control & Flutter Gestures | Trackpads send `PointerPanZoom*`, not scroll events; handle them in raw `Listener`s and test with a trackpad `TestPointer`. | [trackpad-panzoom-scroll-lost.md](trackpad-panzoom-scroll-lost.md) |
| **Bloc Concurrent Event Order** | State Management & Input Streams | `Bloc.on` runs handlers concurrently; use a sequential transformer for ordered device protocols. | [bloc-concurrent-event-order.md](bloc-concurrent-event-order.md) |
| **Bulk Replacement Semantic Drift** | Refactoring Workflow | Audit value-based bulk replacements by call context; equal numbers do not imply equal meaning; never rename identifiers with `sed` (it rewrote import paths). | [bulk-replacement-semantic-drift.md](bulk-replacement-semantic-drift.md) |
| **ParallelWaitError Catch Typing** | Dart Async & Error Handling | Generic `on` clauses can silently never match; let each parallel future return its own result. | [dart-parallel-wait-error-typing.md](dart-parallel-wait-error-typing.md) |
| **macOS systemTemp Is Not /tmp** | Host Paths & Diagnostics | `Directory.systemTemp` is `$TMPDIR` on macOS; pin per-OS paths in tests before centralizing. | [macos-systemtemp-is-not-tmp.md](macos-systemtemp-is-not-tmp.md) |
| **Windows Command Output Differences** | Cross-Platform Parsing | Use `splitLines()`, take the first `where` match, and parse ARP output format-agnostically. | [windows-command-output-differences.md](windows-command-output-differences.md) |
| **Foreign-OS Paths in Host Tests** | Cross-Platform Testing | Test foreign path construction as strings; touch disk only with the host path style. | [foreign-os-paths-in-host-tests.md](foreign-os-paths-in-host-tests.md) |
| **Host-Dependent Test Expectations** | Cross-Platform Testing | Inject relative paths and derive OS-specific labels from production sources so tests pass on any runner. | [host-dependent-test-expectations.md](host-dependent-test-expectations.md) |
| **Plugin Registrants Ship With Dependency** | Flutter Tooling & Commit Hygiene | Commit regenerated `macos/`, `windows/`, `linux/`, `ios/` plugin files with the `pubspec` change; tests won't catch their absence. | [plugin-registrants-ship-with-dependency.md](plugin-registrants-ship-with-dependency.md) |
| **Texture Pixel Order: BGRA vs RGBA** | Native Video & Flutter Textures | Make pixel order an explicit parameter; macOS CVPixelBuffer is BGRA, Windows pixel-buffer textures are RGBA. | [texture-pixel-order-bgra-vs-rgba.md](texture-pixel-order-bgra-vs-rgba.md) |
| **Bundling Third-Party Binaries (adb)** | Distribution & Code Signing | Pin to vendor checksums, ship only imported files, keep the vendor signature, and prefer the user's installed copy. | [bundling-third-party-binaries.md](bundling-third-party-binaries.md) |
| **Dart AOT Under Hardened Runtime** | macOS Code Signing & Distribution | Dart AOT exes need `allow-unsigned-executable-memory` (not `allow-jit`); `dart compile exe` cannot cross-compile to macOS arm64. | [dart-aot-hardened-runtime.md](dart-aot-hardened-runtime.md) |
| **Smoke Test False Pass** | Verification Workflow | Assert on expected output; a silent `exec` failure can exit 0 with empty output. | [smoke-test-false-pass.md](smoke-test-false-pass.md) |
| **scrcpy Version Drift** | Dependencies & Documentation | Read the version from the bundled jar in a test and compare the client constant and README badge to it. | [scrcpy-version-drift.md](scrcpy-version-drift.md) |
| **Pinned Dependency Aged Out** | Dependencies & Android Compatibility | scrcpy v2.1 cannot mirror on Android 15/16; review hidden-API dependencies per Android release and test on the latest OS. | [pinned-dependency-aged-out.md](pinned-dependency-aged-out.md) |
| **Device Verification False Negatives** | Verification Workflow & Android Devices | Mirror the product's retries, wake the screen, run old-vs-new controls, and use pipefail before concluding. | [device-verification-false-negatives.md](device-verification-false-negatives.md) |
| **Windows SDK Macro Identifier Clash** | Native Windows Build | `rpcndr.h` defines `small` as `char`; never use SDK macro names (`small`, `near`, `far`, `interface`) as identifiers. | [windows-sdk-macro-identifier-clash.md](windows-sdk-macro-identifier-clash.md) |
| **Unauthorized Device Silent Black Screen** | Streaming & ADB Authorization | Check `adb devices` state before starting scrcpy and show actionable `StreamStartFailure` guidance instead of a black viewport. | [unauthorized-device-silent-black-screen.md](unauthorized-device-silent-black-screen.md) |
| **Release Script Cross-Platform Artifacts** | Release & Packaging | Delete only your own outputs, push `HEAD:main`, pin download links to a tag when `latest` lacks the asset, guard version copies. | [release-script-cross-platform-artifacts.md](release-script-cross-platform-artifacts.md) |

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
