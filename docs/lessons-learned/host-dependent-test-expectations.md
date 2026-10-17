# Tests That Silently Depended on the Machine Running Them

## 1. Context & Symptoms

During the Windows port (Phase 0), two kinds of tests passed on the developer's Mac but were bound to fail on a Windows CI runner or from another working directory:

- `ScrcpyServerJarLocator` tests expected the release-bundle or temp path, but got `assets/scrcpy-server.jar`.
- A widget test expected the label `⌘K Text`, which is only correct when the test runs on macOS.

## 2. Diagnostic Traces & Evidence

```text
Expected: '/var/folders/.../jar_locator_uAGSFq/Frameworks/App.framework/.../scrcpy-server.jar'
  Actual: 'assets/scrcpy-server.jar'
```

- The locator first checks the **relative** path `assets/scrcpy-server.jar`. `flutter test` runs from the project root, where that file really exists, so the first branch always won.
- `context.shortcuts` falls back to `ShortcutScheme.forOs(HostOs.current)` when no scheme is provided. A widget built in isolation therefore renders `⌘K` on macOS and `Ctrl+K` on Windows.

## 3. Root Cause Analysis

Both tests read **ambient state** that the test did not control: the current working directory and the host OS. They encoded the developer machine's values instead of the behavior under test. The same tests would have failed on `windows-latest` CI, far from the change that caused them.

## 4. Architectural Solution

- `ScrcpyServerJarLocator` takes `devCheckoutPath` (default `assets/scrcpy-server.jar`). Tests pass a path inside their temp folder, so each branch is tested on purpose.
- Widget tests either provide a `ShortcutScheme` with `RepositoryProvider`, or derive the expected text from `ShortcutScheme.forOs(HostOs.current)`.
- Platform-sensitive tests run against **both** schemes (see `logcat_shortcut_handler_test.dart`).
- `registerPlatformDependencies(sl, os: HostOs.macos)` pins the OS for app-level widget tests.

## 5. Prevention & Reusability Checklist

- [ ] Every relative path used in production code is injectable, so tests can point it somewhere they control.
- [ ] Tests never depend on `Directory.current`, `Platform.*`, or the real environment unless that is what they test.
- [ ] A string expectation that differs per OS is computed from the same source as production (`ShortcutScheme`, `HostPaths`).
- [ ] Ask "would this pass on a Windows runner?" before merging any test.
