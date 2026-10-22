# Top-Level Names Shadow Members Inside a Dart Extension

## 1. Context & Symptoms

`McpShellResult` (an extension on `ProcessResult`) read `'$stdout\n$stderr'` to detect "No shell command implementation". Its unit test failed: the marker was never found, so every missing command still counted as success.

## 2. Diagnostic Traces & Evidence

```text
Expected: false (succeeded)   Actual: true
```

`stdout` and `stderr` inside the extension resolved to `dart:io`'s console streams (top-level getters), not to `this.stdout` of the `ProcessResult`. String interpolation printed `Instance of 'IOSink'`. The analyzer gave no warning.

## 3. Root Cause Analysis

In an extension, unqualified identifiers use lexical scope first: a top-level declaration in scope (here, imported from `dart:io`) wins over a member of the extended type. Inside a class body the member would win, so the code looked correct.

## 4. Architectural Solution

Use `this.stdout` / `this.stderr` explicitly, with a comment explaining why (`unnecessary_this` does not fire, because the qualifier changes the meaning).

## 5. Prevention & Reusability Checklist

- [ ] In extensions, qualify members with `this.` when a top-level name could match (`stdout`, `stderr`, `exitCode`, `pid` from `dart:io`).
- [ ] Unit-test extension getters with real values; this bug was invisible to the analyzer and to code review.
