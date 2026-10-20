# Platform Abstraction Layer

> How Azdroid keeps macOS and Windows equally maintainable. Read this before adding any code that behaves differently per OS.

---

## 1. The Rule

**All OS differences live in `lib/core/platform/`.** Features, cubits, and data sources depend only on the contracts defined there.

`test/architecture/platform_isolation_test.dart` fails the build if code outside `lib/core/platform/` (and `platform_di.dart`) uses:

- `Platform.isX`, `Platform.environment`, `Platform.operatingSystem`, `Platform.pathSeparator`
- Hard-coded tool paths (`/usr/bin/...`, `/opt/homebrew/...`, `C:\`)
- macOS-only shell tools (`osascript`, `pbcopy`, `/usr/bin/open`)
- `split('\n')` on text (use `splitLines()`)

---

## 2. Layout

```text
lib/core/platform/
├── host_os.dart                     # HostOs enum (macos, windows, linux)
├── host_paths.dart                  # Home, Downloads, app data, temp, logs, bundled assets
├── host_toolchain.dart              # adb/aapt names, SDK roots, `which`/`where`, arp
├── file_picker/
│   └── host_file_picker.dart        # Contract + one cross-platform impl (file_selector)
├── file_launcher/
│   ├── host_file_launcher.dart      # Contract
│   ├── mac_host_file_launcher.dart  # /usr/bin/open
│   └── windows_host_file_launcher.dart  # explorer.exe
├── image_clipboard/
│   ├── image_clipboard.dart         # Contract
│   ├── mac_image_clipboard.dart     # osascript «class PNGf»
│   └── windows_image_clipboard.dart # PowerShell -STA + System.Windows.Forms
└── shortcuts/
    └── shortcut_scheme.dart         # ⌘ vs Ctrl: key handling + labels
lib/core/di/modules/platform_di.dart # The only place that picks implementations
```

---

## 3. Choosing the Right Tool

| Kind of difference | Mechanism | Example |
|:---|:---|:---|
| Only **data** differs (names, folders, flags) | Add a field to a data object built per OS | `HostToolchain.pathLookupCommand` (`which` / `where`) |
| A **cross-platform package** already exists | One implementation, no OS code | `FileSelectorHostFilePicker` |
| **Behavior** differs | Strategy: one contract + one class per OS, side by side | `MacHostFileLauncher` / `WindowsHostFileLauncher` |
| Output **format** differs, data is the same | One format-agnostic parser | `ArpTableParser`, `splitLines()` |

Prefer the options higher in the table. A new Strategy is the last resort.

---

## 4. Recipe: Adding an OS-Specific Behavior

1. Create `lib/core/platform/<concern>/<concern>.dart` with an abstract contract and doc comments.
2. Add `mac_<concern>.dart` and `windows_<concern>.dart` next to it. Keep the class shapes symmetric.
3. Register the contract in `platform_di.dart` with a `switch (hostOs)`.
4. Inject the contract as a **required** constructor parameter. Never default to one OS's class.
5. Add `test/unit/platform/<concern>_test.dart` with a **shared contract suite** that loops over both implementations, plus OS-specific edge cases (escaping, exit codes).

---

## 5. Testing Rules

- Build fixed environments with `SystemHostPaths(os: ..., environment: ..., systemTempPath: ...)` and `toolchainFor(os, env)` from `test/helpers/test_toolchains.dart`. Never read the real machine's environment in tests.
- Test foreign-OS paths as **strings**. Only touch disk with the host's own path style (see [lessons-learned/foreign-os-paths-in-host-tests.md](lessons-learned/foreign-os-paths-in-host-tests.md)).
- Widget tests that check shortcut labels provide a `ShortcutScheme` or derive the expected label from it.
- Parser tests include CRLF fixtures.

---

## 6. Native Code

Dart-side rules above cover `lib/`. For native code, the same idea applies: protocol logic lives once in `native/scrcpy_core` (no OS headers), and `macos/Runner` and `windows/scrcpy_stream` are thin adapters. See [native-video-contract.md](native-video-contract.md).

---

## 7. Known Platform Quirks Encoded Here

| Quirk | Where handled |
|:---|:---|
| `where` prints several matches | `AdbBinaryLocator`, `AaptPathResolver` take the first line |
| `explorer.exe` exits with code 1 on success | `WindowsHostFileLauncher` ignores the exit code |
| `Clipboard.SetImage` needs an STA thread | `WindowsImageClipboard` runs PowerShell with `-STA` |
| `Directory.systemTemp` is `$TMPDIR` on macOS | `SystemHostPaths.diagnosticLogFile` keeps `/tmp` on POSIX |
| Release assets: `App.framework` (macOS) vs `data\flutter_assets` (Windows) | `SystemHostPaths.flutterAssetPath` |
| Texture pixel order: BGRA (macOS) vs RGBA (Windows pixel buffer) | `scrcpy_core::PixelOrder` |
