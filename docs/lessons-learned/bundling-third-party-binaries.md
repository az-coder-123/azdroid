# Bundling a Third-Party Binary (adb) Into the App

## 1. Context & Symptoms

Azdroid required users to install `adb` themselves (Homebrew, winget, or Android Studio). The goal was a self-contained app. Shipping someone else's native binary raised four questions: where to get a trustworthy copy, which files are really needed, how it interacts with code signing, and what happens when the user also has an adb installed.

## 2. Diagnostic Traces & Evidence

- **Provenance:** `repository2-3.xml` lists `platform-tools` 37.0.1 with size and SHA-1 per OS. Both downloads matched Google's SHA-1.
- **macOS dependencies:** `otool -L adb` showed only system frameworks; `lipo -archs` showed `x86_64 arm64`.
- **macOS signature:** `codesign -dv adb` showed `TeamIdentifier=EQHXZ8M8AV` and `flags=0x10000(runtime)`. The binary was already signed by Google with hardened runtime.
- **Windows dependencies:** the import table of `adb.exe` lists `AdbWinApi.dll` (which loads `AdbWinUsbApi.dll`), but not `libwinpthread-1.dll`, which other platform-tools need.
- **Size:** the macOS adb is 18.8 MB, larger than the 6–15 MB estimated before measuring.
- **Docs vs code:** the new troubleshooting entry told users to read "which adb" from the log, but the app never logged it.

## 3. Root Cause Analysis

Each risk came from treating the binary as a black box:

- Trusting the first download (trust on first use) would pin whatever was received, including a tampered file.
- Copying the whole platform-tools folder would ship ~38 MB of unused tools, while guessing a subset could miss a needed DLL.
- Re-signing ad hoc would have replaced Google's Developer ID signature with a weaker one.
- Preferring the bundled adb would fight with Android Studio's adb over the shared server.

## 4. Architectural Solution

- One Dart manifest holds version, URLs, sizes, SHA-1 (provenance), and SHA-256 (verified on every fetch). It is the single source for both platforms.
- The extracted file list comes from the binaries' own import tables.
- The macOS embed script verifies Google's signature and never re-signs.
- `HostToolchain.adbSearchPaths` puts the bundled copy **last**.
- Release builds fail without the bundled adb; Debug builds only warn.
- The app logs `Using installed/bundled ADB at …`, which the docs reference.
- Binaries stay out of git (`vendor/`, gitignored); the fetch tool is idempotent.

## 5. Prevention & Reusability Checklist

- [ ] Pin third-party binaries to checksums published by the vendor, not to the first download.
- [ ] Derive the shipped file set from the binary's imports (`otool -L`, the PE import table).
- [ ] Check the existing signature (`codesign -dv`) before deciding to sign.
- [ ] When a bundled tool shares global state (a server, a port, a config folder), prefer the user's installed copy.
- [ ] Make release builds fail when a required bundled file is missing.
- [ ] Measure sizes before quoting them.
- [ ] When documentation tells users to look for a log line, confirm the code writes it.
