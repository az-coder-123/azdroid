# Empty `catch` Blocks Hid Broken Mocks and Missing Providers

## 1. Context & Symptoms

Azdroid had ten `catch (_) {}` blocks in data sources, resolvers, and the viewport keyboard handler. Everything appeared to work, and every test passed.

After replacing them with typed handlers (`on Exception catch`) and logging, one existing test failed at once:

```
type 'Null' is not a subtype of type 'Future<ProcessResult>'
  MockProcessExecutor.run
  FileTransferDatasourceImpl._scanRemoteMedia
```

## 2. Diagnostic Traces & Evidence

- `pushFile` triggers a best-effort `am broadcast` media scan after a push.
- The test stubbed only `adb push`. Mocktail returned `null` for the unstubbed `am broadcast` call, which caused a `TypeError`.
- The old `catch (_) {}` swallowed that `TypeError`, so the test passed while exercising a code path that could never succeed.
- In `ViewportKeyEventHandler`, `try { context.read<ScreenshotCubit>() } catch (_) {}` also hid `ProviderNotFoundException` and any real error thrown by the cubit call inside the same block.

## 3. Root Cause Analysis

`catch (_)` catches **errors** (programming bugs such as `TypeError` and `StateError`) as well as **exceptions** (expected runtime failures such as `ProcessException` and `FileSystemException`). Swallowing both turns bugs into silent no-ops. Tests cannot detect what the code throws away.

## 4. Architectural Solution

| Situation | Replacement |
|:---|:---|
| Best-effort I/O (media scan, icon extraction) | `on Exception catch (e)` + `AppLogger.debug` |
| Recoverable boundary failure | `on FileSystemException` / `on Exception` + `AppLogger.warning` |
| Optional provider in the widget tree | `context.tryRead<T>()` (catches only `ProviderNotFoundException`) |
| Pure Dart code without Flutter (MCP server) | `AdbBinaryLocator.onProbeFailure` callback, routed to `stderr` |
| Fire-and-forget future | `unawaited(...)` with a comment explaining why |

The broken test now stubs the media scan call explicitly. The `empty_catches` and `unawaited_futures` lints are enabled in `analysis_options.yaml` so the pattern cannot return.

## 5. Prevention & Reusability Checklist

- [ ] Never write `catch (_) {}`. Catch the narrowest type and log it.
- [ ] Do not catch `Error` subclasses at all unless you are at a top-level isolate or stream boundary.
- [ ] Keep `try` blocks small, so a catch for one call does not hide failures in the next call.
- [ ] Prefer explicit APIs (`tryRead`, nullable returns) over exceptions for expected absence.
- [ ] When you tighten error handling, run the full test suite: newly failing tests often reveal incomplete mocks.
