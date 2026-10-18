# README Advertised scrcpy v3.1 While the App Shipped v2.1

## 1. Context & Symptoms

The README badge said **"scrcpy v3.1 Engine"**, but `ScrcpyServerManager.serverVersion` was `'2.1'`. Mirroring worked, so nothing in the app looked broken. The mismatch was spotted only while listing the project's external dependencies.

## 2. Diagnostic Traces & Evidence

- The bundled `assets/scrcpy-server.jar` is an Android package; its version is a string constant inside `classes.dex`:
  ```text
  $ unzip -o assets/scrcpy-server.jar -d jar && strings -n 3 jar/classes.dex | grep "does not match"
  The server version (2.1) does not match the client (
  ```
- scrcpy-server compares that version with the first argument the client sends and exits on a mismatch. The app sends `2.1`, so the jar must be 2.1, which explains why mirroring worked.
- Only the README was wrong. The badge also linked to this repository's stargazers page instead of the scrcpy release.

## 3. Root Cause Analysis

The version lived in three places (the jar, a Dart constant, a README badge) and nothing tied them together. The runtime check covers the jar and the constant, so they cannot drift without breaking mirroring. No check covered the badge, so it drifted silently.

## 4. Architectural Solution

- The README badge now says v2.1 and links to the scrcpy v2.1 release.
- `test/unit/scrcpy_server_version_test.dart` extracts the version from `classes.dex` and asserts that the Dart constant and the README badge match it. A mutation run (badge set back to v3.1) makes the test fail.
- `docs/native-video-contract.md` records the pinned version and the upgrade steps.

## 5. Prevention & Reusability Checklist

- [ ] When a version appears in several places, read it from the artifact itself in a test and compare every copy.
- [ ] Treat badges and marketing copy as data that tests can check.
- [ ] When upgrading a bundled binary, search the repository for its old version string.
