# Lesson Learned: Background Polling Churn & UI Jank Elimination in Flutter Desktop

> **Category:** Flutter Performance / State Management / Reactive UI Optimization  
> **Impact:** UI flashing, lost keyboard focus in dialogs, and high CPU churn during periodic background scans.

---

## 1. Context & Symptoms

To detect newly plugged USB devices, mDNS Wi-Fi announcements, and battery level updates, Azdroid runs periodic background scans (e.g., every 5 seconds) via `DiscoveryCubit`:
- **Full-Screen Loading Flashes:** Every 5 seconds, the main device dashboard was replaced by a full-screen `CircularProgressIndicator` for 300-500ms, causing unbearable visual flickering.
- **Focus Destruction:** If a user was actively typing into a modal dialog (such as the Manual Connect IP field or pairing code inputs), the periodic scan tore down the underlying view, stealing keyboard focus and clearing active inputs.
- **Unnecessary CPU Spikes:** macOS Activity Monitor reported continuous 25-35% CPU usage even when the app was idle on the home screen.

---

## 2. Diagnostic Traces & Evidence

Flutter DevTools Widget Rebuild Tracker revealed:
1. `DiscoveryCubit.scanDevices()` was emitting:
   ```text
   DiscoveryInitial ➔ DiscoveryLoading ➔ DiscoveryLoaded (Scan 1)
   DiscoveryLoading ➔ DiscoveryLoaded (Scan 2 - 5s later)
   DiscoveryLoading ➔ DiscoveryLoaded (Scan 3 - 10s later)
   ```
2. The root page's `BlocBuilder<DiscoveryCubit, DiscoveryState>` was evaluating `state is DiscoveryLoading` and returning `const Center(child: CircularProgressIndicator())` on every timer tick.
3. Over 180 widget rebuilds were triggered across the tree every 5 seconds, even when the resulting device list was completely identical.

---

## 3. Root Cause Analysis

### A. Monolithic Loading States for Background Operations
Conflating **User-Initiated Loading** (first app launch or manual refresh click) with **Background Polling** (scheduled timer ticks). Background operations must never transition the UI into a blocking loading state.

### B. Unconstrained `BlocBuilder` Rebuild Boundaries
Widgets were listening to the entire `DiscoveryCubit` stream without specifying `buildWhen` filtering predicates. Consequently, any state change—including identical data emissions—forced Flutter to execute `build()` on the entire view hierarchy.

---

## 4. Architectural Solution: Silent Scanning & Targeted Build Predicates

Implemented a three-part optimization pattern across `DiscoveryCubit` and the presentation widgets:

### A. Silent Background Scanning Mode
Introduced a `silent` parameter in `DiscoveryCubit.scanDevices`:

```dart
Future<void> scanDevices({bool silent = false}) async {
  final currentState = state;
  // Only enter full-screen loading if this is an explicit first-time load
  if (!silent || currentState is! DiscoveryLoaded) {
    emit(const DiscoveryLoading());
  } else {
    // Retain existing loaded view while updating a subtle background status pill
    emit(DiscoveryLoaded(devices: currentState.devices, isAutoScanning: true));
  }

  try {
    final devices = await repository.discoverDevices();
    emit(DiscoveryLoaded(devices: devices, isAutoScanning: false));
  } catch (e) {
    // Handle error boundary...
  }
}
```

### B. Defensive `buildWhen` Constraints
Constrained rebuild boundaries using `BlocBuilder.buildWhen` to verify whether the device list actually changed:

```dart
BlocBuilder<DiscoveryCubit, DiscoveryState>(
  buildWhen: (previous, current) {
    // Only rebuild the layout if state type changed or device contents differed
    if (previous.runtimeType != current.runtimeType) return true;
    if (previous is DiscoveryLoaded && current is DiscoveryLoaded) {
      return previous.devices != current.devices;
    }
    return true;
  },
  builder: (context, state) { ... },
)
```

### C. Subtle Background Radar Animation
Rather than flashing spinners, a discreet pulsing radar dot in the header bar indicates periodic background activity without interrupting mouse or keyboard interactions.

---

## 5. Prevention & Reusability Checklist

- [ ] **Distinguish Initial Loads from Polling Ticks:** Always support a `silent: true` mode in Cubit/BLoC methods triggered by background `Timer.periodic`.
- [ ] **Guard Rebuilds with `buildWhen` / `select`:** Never allow background state emissions with identical data to trigger full `build()` cycles.
- [ ] **Never Destroy Active Focus with Loading Views:** If user interaction (text fields, scroll positions, dialogs) can occur while data refreshes, keep the existing view mounted and update data in-place.
