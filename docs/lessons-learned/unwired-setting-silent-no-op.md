# A Setting That Did Nothing: `stayAwake` Was Never Wired

## 1. Context & Symptoms

Azdroid had a `stayAwake` setting (default `true`, documented as "keep the Android device awake while connected"). In practice, a mirrored phone still went to sleep after its own screen timeout, and the mirror froze. No error appeared anywhere.

## 2. Diagnostic Traces & Evidence

- `AppSettingsEntity.stayAwake` was declared, copied, and compared, but no code read it. The whole entity had no users, and there was no settings screen.
- `ScrcpyServerManager.startServerDaemon({bool stayAwake = true})` accepted the flag and never used it. `StreamingRepositoryImpl` never passed it.
- The scrcpy server command contained no `stay_awake` option, so the server never changed anything.

## 3. Root Cause Analysis

The setting was added at the edges (an entity field and a method parameter) but never connected end to end. Both ends defaulted to `true`, so the code read as if the feature worked. Unused parameters with defaults raise no analyzer warning, and no test asserted that the value reached the server.

## 4. Architectural Solution

- One source of truth: `MirroringPreferences.stayAwake` in the streaming domain, loaded by `StreamingCubit.startSession` and saved on toggle. The duplicate field was removed from the unused `AppSettingsEntity`, and later the whole entity and its empty `settings` feature were deleted.
- The value travels explicitly: cubit → `StreamingRepository.startSession(stayAwake:)` → `ScrcpyServerManager.startServerDaemon(stayAwake:)` → `ScrcpyServerCommand.adbArguments(required stayAwake)`. The command builder makes the flag **required**, so a new caller cannot forget it.
- Tests cover each hop: command arguments with and without the flag, the repository passing it to the server and keeping it across a bitrate restart, the cubit using the saved value, and an on-device check in the verification tool.

## 5. Prevention & Reusability Checklist

- [ ] A user-facing option needs a test that asserts its effect at the boundary (here, the server arguments), not only that it is stored.
- [ ] Make option parameters `required` at the lowest layer that turns them into behavior; defaults hide unwired callers.
- [ ] Search for reads of a field before trusting its documentation; a field that is only written is a warning sign.
- [ ] Remove or wire unused entities instead of leaving them as apparent features.
