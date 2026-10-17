# Generated Plugin Registrants Must Ship With the Dependency

## 1. Context & Symptoms

Phase 0 of the Windows port added `file_selector` to `pubspec.yaml`. While splitting the work into commits, the first two commits included `pubspec.yaml`, `pubspec.lock`, and all Dart code. A final `git status` still showed modified files outside `lib/` and `test/`:

```text
macos/Flutter/GeneratedPluginRegistrant.swift
windows/flutter/generated_plugin_registrant.cc
windows/flutter/generated_plugins.cmake
linux/flutter/generated_plugin_registrant.cc
linux/flutter/generated_plugins.cmake
ios/Flutter/Debug.xcconfig, ios/Flutter/Release.xcconfig, ios/Podfile
```

## 2. Diagnostic Traces & Evidence

`flutter pub get` regenerates these files whenever a package with a native plugin is added:

```diff
+import file_selector_macos
+  FileSelectorPlugin.register(with: registry.registrar(forPlugin: "FileSelectorPlugin"))
```

Without them, `flutter analyze` and `flutter test` still pass, because tests never load native plugins. A real build, however, has no registered `file_selector` plugin, and the file picker fails at runtime with `MissingPluginException`.

## 3. Root Cause Analysis

The commits were scoped with `git add lib test bin`, a habit from Dart-only changes. Native registrants live in the platform folders, and no automated check covers them, so a green CI result would not have revealed the gap.

## 4. Architectural Solution

The unpushed branch was rebuilt (`git reset --mixed <base>`). The registrants and iOS CocoaPods hooks were placed in the **same commit as the dependency** (`feat(platform): add host OS, paths, and toolchain foundations`), so every commit that uses `file_selector` can build and run.

## 5. Prevention & Reusability Checklist

- [ ] After `flutter pub add <plugin>`, run `git status` and commit every changed file under `macos/`, `windows/`, `linux/`, and `ios/` together with `pubspec.yaml`.
- [ ] Before the last commit of a series, confirm `git status --short` is empty, or that every remaining file is intentionally excluded.
- [ ] Remember that green unit tests do not prove native plugins are registered; launch the app (or run `flutter build`) after adding a plugin.
- [ ] `macos/Podfile.lock` changes only after the first macOS build runs `pod install`, not after `pub get`. Build once before committing a new plugin, or commit the lock file as soon as it appears (it surfaced one phase later for `file_selector_macos`).
