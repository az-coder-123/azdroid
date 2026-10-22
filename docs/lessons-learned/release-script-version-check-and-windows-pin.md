# The Release Script's Version Check Could Not Run, and the Windows Pin Was Manual

## 1. Context & Symptoms

On 2026-10-22, the first `./scripts/deploy.sh minor --dry-run` for v1.4.0 stopped at "Version alignment test failed!" although `flutter test test/unit/app_version_test.dart` passed. The same review found the README's Windows badge pointing at `/releases/latest/download/Azdroid-v1.3.0-Windows-x64.zip`, which would return 404 as soon as a macOS-only v1.4.0 became "latest". The dry run had also edited `pubspec.yaml` and `app_constants.dart` (it is a local run without push, not a no-op).

## 2. Diagnostic Traces & Evidence

```bash
dart test test/unit/app_version_test.dart
#   flutter_test/lib/src/animation_sheet.dart: Error: 'Image' isn't a type.
#   Failing tests: loading test/unit/app_version_test.dart
```

The test imports `package:flutter_test`, which needs the Flutter engine; `dart test` cannot load it. The step had been added with the pipeline (454c65e) and never ran successfully: v1.3.0 was released before it.

## 3. Root Cause Analysis

- The check used the wrong runner and hid its output (`>/dev/null 2>&1`), so the failure gave no reason.
- The anti-404 rule existed only as text in the runbook and `AGENTS.md`; the script updated macOS links and left Windows links to a person.

## 4. Architectural Solution

- `scripts/deploy.sh` runs the check with `flutter test`.
- Step 4 rewrites any `releases/latest/download/Azdroid-v<x>-Windows-x64.zip` to `releases/download/v<x>/…` (the tag in the file name has the asset) and stops if a Windows `latest` link remains.
- Release notes for v1.4.0 were written by hand before the run (the script keeps an existing notes file), instead of the commit-title draft.

## 5. Prevention & Reusability Checklist

- [ ] Run every step of a release script once on a test version before relying on it.
- [ ] Never silence the output of a check that can fail; print it on failure.
- [ ] Turn release rules from documents into script checks.
- [ ] Revert the files a dry run edits (`git checkout -- pubspec.yaml lib/core/constants/app_constants.dart`).
