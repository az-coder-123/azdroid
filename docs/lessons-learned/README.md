# Engineering Lessons Learned & Technical Post-Mortems

> A curated repository of real-world edge cases, operating system quirks, networking anomalies, and reusable architectural solutions discovered during WifiDesk development.

---

## 🎯 Purpose & Philosophy

As an advanced desktop mirroring and remote control utility bridging macOS and Android, WifiDesk interfaces directly with low-level kernel routing, daemon socket lifetimes, USB/Wi-Fi switching, and device permissions.

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

---

## 📐 Authoring Standard for New Lessons

Every new case study added to this directory must adhere strictly to the following standards:

1. **Strict Single Responsibility Principle (SRP):**
   - Each file must cover exactly **one** distinct issue or failure scenario.
   - Keep the file compact and readable (< 250 lines).
2. **Mandatory 5-Section Structure:**
   - **1. Context & Symptoms:** What failed? Exact error messages, error codes, and observable UI state.
   - **2. Diagnostic Traces & Evidence:** Exact terminal commands, log snippets (`wifidesk_dart.log`), and reproduction steps.
   - **3. Root Cause Analysis:** Deep technical explanation of why the failure occurred (OS kernel, networking, daemon state, etc.).
   - **4. Architectural Solution:** How it was resolved in code, design patterns used, and code references.
   - **5. Prevention & Reusability Checklist:** Rules of thumb for engineers to reuse or avoid in other features.
3. **Professional Language:**
   - Written exclusively in professional, concise, and plain English.
