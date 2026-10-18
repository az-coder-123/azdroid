# Bulk Replacement Assigned the Wrong Semantic Constant

## 1. Context & Symptoms

To remove magic numbers, every `timeout: const Duration(seconds: N)` was replaced by script with a tier from `AdbTimeouts` (`3s → quickQuery`, `4s → shellCommand`, ...). The analyzer and all tests passed.

A later review found `AdbTimeouts.quickQuery` on an **`osascript`** call in `screenshot_datasource.dart`, a local macOS command that has nothing to do with ADB.

## 2. Diagnostic Traces & Evidence

A follow-up script listed every `AdbTimeouts.*` use whose preceding `.run(` target did not mention `adb`:

```text
lib/features/productivity/data/datasources/screenshot_datasource.dart  .run('/usr/bin/osascript'
lib/features/intent_dispatcher/data/datasources/intent_datasource.dart .run(   <- adb, multi-line call
```

One was a real misuse; the other was a false positive (the `adb` variable was on the next line).

A second case followed in the Windows Phase 0 work: after removing a few `const` keywords, `dart fix --apply --code=prefer_const_constructors,prefer_const_literals_to_create_immutables lib` also rewrote `mcp_protocol_handler.dart`, a file unrelated to the change. `git diff --stat` caught it before commit, and the file was restored.

## 3. Root Cause Analysis

The regex keyed on the **value** (`seconds: 3`), not on the **meaning** (an ADB command). Equal numbers do not imply equal intent. Tools like `flutter analyze` cannot detect a constant that compiles but carries the wrong name. Likewise, `dart fix` applies a rule to **every** file in the target path, not only to the files you touched.

## 4. Architectural Solution

- The `osascript` timeout became a local, named constant: `_clipboardScriptTimeout`.
- The audit script was kept as a review step for later bulk changes.

## 5. Prevention & Reusability Checklist

- [ ] After a value-based bulk replacement, audit by **context**: list each new usage with its call target.
- [ ] Name tiers after what they protect (`AdbTimeouts`), and use them only for that domain.
- [ ] One-off timings get a private, descriptive constant next to their only use.
- [ ] Review bulk diffs file by file; do not rely only on green analysis and tests.
- [ ] Scope `dart fix` to the files you changed, or check `git diff --stat` right after it and revert unrelated files.

## Recurrence: Field Rename by `sed` Broke Import Paths (2026-10-18)

- **Symptom:** after renaming private fields with `sed 's/_tools\./_hostTools./g'` (and `_repository.`, `_files.`), `flutter analyze` reported `uri_does_not_exist` for `host_process_hostTools.dart` and `mcp_status_statusRepository.dart`.
- **Cause:** the pattern also matched inside import URIs (`host_process_tools.dart` contains `_tools.`). Text patterns do not know Dart scopes.
- **Fix:** imports restored by hand; analyze and tests clean.
- [ ] Rename identifiers with an IDE or analyzer rename, not `sed`; if `sed` is unavoidable, anchor the pattern to code (`\b_tools\.[a-z]`) and exclude `import` lines.
