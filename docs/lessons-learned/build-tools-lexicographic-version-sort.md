# Android build-tools Picked by String Order Instead of Version Order

## 1. Context & Symptoms

DeskDroid inspects APK files with `aapt2`/`aapt`. When the tool is not on `PATH`, it searches `~/Library/Android/sdk/build-tools/<version>/` and is meant to use the newest version.

On machines with an old and a new build-tools folder (for example `9.0.0` and `34.0.0`), DeskDroid used the **oldest** one. Old `aapt` versions can fail to read modern APKs (newer resource table formats, `targetSdkVersion` 34+), so the installer showed only the file name with no package, label, or icon.

## 2. Diagnostic Traces & Evidence

The original resolver sorted directories by path:

```dart
..sort((a, b) => b.path.compareTo(a.path)); // "Latest first"
```

String comparison is character by character:

| Pair | String order | Version order |
|:---|:---|:---|
| `9.0.0` vs `34.0.0` | `9.0.0` first (`'9' > '3'`) | `34.0.0` first |
| `30.0.10` vs `30.0.3` | `30.0.3` first (`'3' > '1'`) | `30.0.10` first |

The comment said "latest first", but that only holds when every version has the same number of digits.

## 3. Root Cause Analysis

Version names are dotted numbers, not strings. Lexicographic order matches numeric order only for fixed-width segments. The bug stayed hidden because most developers install one build-tools version, and the existing test mocked `which aapt2` and never reached the SDK fallback.

## 4. Architectural Solution

- Moved discovery into `AaptPathResolver` (`lib/features/apk_installer/data/services/aapt_path_resolver.dart`) so the datasource keeps one job: parsing `aapt dump badging`.
- Added `AaptPathResolver.compareVersionNames`, which compares segment by segment as integers, treats missing segments as `0`, and falls back to string comparison for non-numeric parts such as `-rc1`.
- Sort the folders with `compareVersionNames(bName, aName)` so the newest version comes first.
- Added tests with real temporary folders `9.0.0` and `34.0.0` that assert `34.0.0` wins.

## 5. Prevention & Reusability Checklist

- [ ] Never sort version strings with `String.compareTo`. Use a numeric segment comparator.
- [ ] When a comment states an ordering ("latest first"), add a test with values of different widths.
- [ ] Test the fallback branch of every resolver, not only the happy path.
- [ ] Reuse `compareVersionNames` for NDK, platform-tools, or any other SDK version folder.
