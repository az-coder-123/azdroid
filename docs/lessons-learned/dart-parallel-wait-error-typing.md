# `ParallelWaitError` Catch Clause Never Matched

## 1. Context & Symptoms

`HostContextCubit.load()` fetched the host IP and recent devices in parallel with record `.wait`:

```dart
final (ip, recents) = await (_networkInfo.getLocalIpAddress(), _history.getRecentDevices()).wait;
// ...
} on ParallelWaitError<(String?, List<RecentDevice>), dynamic> catch (error) {
```

The code compiled cleanly, but on review the catch clause was found **unable to match** the error actually thrown.

## 2. Diagnostic Traces & Evidence

- When any future fails, `.wait` on a record throws `ParallelWaitError<V, E>`. `V` is the record of **nullable** results, so failed slots can be `null`: here `(String?, List<RecentDevice>?)`.
- `(String?, List<RecentDevice>?)` is not a subtype of `(String?, List<RecentDevice>)`, so `on ParallelWaitError<(String?, List<RecentDevice>), dynamic>` is skipped.
- The error would have escaped the cubit and left the state stuck in `loading`.

## 3. Root Cause Analysis

Generic type arguments in `on` clauses are checked at runtime. A slightly wrong type argument does not cause a compile error; the clause just never runs. This makes the bug invisible until the failure path executes.

## 4. Architectural Solution

The method was rewritten so that each source handles its own errors and returns a `({bool ok, T? value})` record. `load()` no longer needs any typed parallel error:

```dart
final (ip, recents) = await (_loadHostIp(), _loadRecentDevices()).wait;
final failed = !ip.ok || !recents.ok;
```

A bloc test covers the "history fails, IP succeeds" path.

## 5. Prevention & Reusability Checklist

- [ ] Avoid generic type arguments in `on` clauses unless a test throws exactly that type.
- [ ] For partial-failure parallel work, let each future catch its own errors and return a result value.
- [ ] Every `catch` branch needs a test that actually reaches it.
