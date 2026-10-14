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
