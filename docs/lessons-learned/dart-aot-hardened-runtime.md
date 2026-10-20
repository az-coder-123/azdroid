# Dart AOT Executables Under the macOS Hardened Runtime

## 1. Context & Symptoms

To spare MCP users the Dart SDK, release builds now ship `bin/deskdroid_mcp.dart` compiled with `dart compile exe` inside `Azdroid.app/Contents/MacOS/deskdroid-mcp`. Signed with the hardened runtime (required for notarization), the server **exited immediately with code 137** and printed nothing.

## 2. Diagnostic Traces & Evidence

The same binary was signed four ways and fed `initialize` + `tools/list` over stdin:

| Signature | Exit | JSON-RPC replies |
|:---|:---|:---|
| As produced by `dart compile exe` (ad hoc) | 0 | 2 |
| `codesign --sign -` (ad hoc, no runtime) | 0 | 2 |
| `--options runtime` | **137** (SIGKILL) | 0 |
| runtime + `com.apple.security.cs.allow-jit` | **137** | 0 |
| runtime + `com.apple.security.cs.allow-unsigned-executable-memory` | 0 | 2 |
| runtime + `com.apple.security.cs.disable-executable-page-protection` | 0 | 2 |

Exit 137 is SIGKILL from the kernel's code-signing enforcement, not a crash in Dart code (a timeout would be 142, SIGALRM).

A second constraint appeared on the Intel build machine:

```text
$ dart compile exe ... --target-os=macos --target-arch=arm64
Unsupported target platform macos_arm64.
Supported target platforms: linux_arm, linux_arm64, linux_riscv64, linux_x64
```

## 3. Root Cause Analysis

A Dart AOT executable maps its embedded snapshot as executable memory that is not covered by the code signature. The hardened runtime forbids that unless the binary holds `allow-unsigned-executable-memory`. `allow-jit` only covers `MAP_JIT` pages, which the Dart runtime does not use for snapshots. `disable-executable-page-protection` also works, but it removes more protection than needed.

`dart compile exe` cross-compiles only to Linux, so a macOS binary always matches the build machine's CPU.

## 4. Architectural Solution

- `macos/Runner/McpServer.entitlements` grants only `allow-unsigned-executable-memory`.
- `macos/scripts/embed_mcp_server.sh` (Release only) compiles the server, signs it with the app identity, hardened runtime, and those entitlements, then verifies it. The app itself keeps its own signature.
- `scripts/build_release.sh` fails unless the bundled server answers `tools/list`.
- Architecture: the shipped server matches the build machine (x86_64 on the current Intel builder; it runs on Apple Silicon via Rosetta 2). This is documented in `docs/mcp-setup-guide.md`.

## 5. Prevention & Reusability Checklist

- [ ] Test every nested executable **with the final signature flags**, not as the compiler left it.
- [ ] Treat exit 137 right after launch on macOS as a code-signing kill first.
- [ ] Grant the narrowest entitlement that works; try them one at a time.
- [ ] Before promising a universal binary, check that the compiler can target every architecture.
