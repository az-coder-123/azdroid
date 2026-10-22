# Open Sockets and Timers Keep a Dart CLI Alive

## 1. Context & Symptoms

After the scrcpy touch session was added, the MCP server no longer exited when its client closed stdin: the test driver waited 30 seconds and timed out, and the process had to be killed. A killed process left an `adb forward tcp:61534 localabstract:scrcpy_303abf14` behind.

## 2. Diagnostic Traces & Evidence

`McpStdioTransport.run()` returns when stdin closes and `main` ends, but the isolate stays alive while it has open resources: the session's `Socket`, the server's `Process` (adb shell) streams, and the 2-minute idle `Timer`.

## 3. Root Cause Analysis

A Dart program exits when its event loop has nothing left to wait for, not when `main` returns. Long-lived resources owned by a static registry are invisible to the code that ends the program.

## 4. Architectural Solution

`McpScrcpyTouchSession.closeAll()` closes every session (socket, server process, timer, `adb forward --remove`); `bin/azdroid_mcp.dart` calls it after the transport ends. Verified: a run with four gesture calls exited normally, and `adb forward --list` showed only Azdroid's own mirroring forward.

## 5. Prevention & Reusability Checklist

- [ ] Every static registry of sockets, processes, or timers needs a close-all that the entry point calls on shutdown.
- [ ] Test that the CLI exits after stdin closes, not only that its calls succeed.
- [ ] Prefer per-session cleanup that also runs when the peer closes the connection.
