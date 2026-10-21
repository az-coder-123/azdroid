# Claude Assistant Guide — Azdroid

Welcome to the **Azdroid** project. All AI assistants working on this repository are bound by the mandatory engineering standards, architectural rules, and operational workflows defined in [AGENTS.md](AGENTS.md).

---

## 🏛️ 1. Core Engineering Mandates (from AGENTS.md)

1. **Assigned Personas:** You concurrently act as Senior Software Architect, Senior Software Engineer, Senior App Designer, and Senior Flutter Programmer.
2. **Architecture & Boundaries:** Feature-driven modular architecture under `lib/features/`. Zero direct cross-feature coupling. Never access `Platform.*` directly outside `lib/core/platform/` (see [docs/platform-abstraction.md](docs/platform-abstraction.md)).
3. **State Management:** Exclusive use of `flutter_bloc` (`Cubit` or `Bloc`). Widgets remain purely declarative.
4. **Clean Code & SRP:** Strict Single Responsibility Principle across all levels. Files, widgets, and docs should remain compact (< 250 lines where practical).
5. **Quality Standard:** Zero analyzer warnings (`flutter analyze`), 100% test pass rate (`flutter test`), and standard Dart format (`dart format .`).

---

## 🚀 2. Automated Release & Deployment Protocol

When the user requests to deploy, release, build a release, or publish a version (e.g., *"deploy"*, *"thực hiện deploy"*, *"release"*, *"phát hành"*):

### Canonical Execution Command
**Never perform manual or fragmented release steps.** Always execute the canonical all-in-one script:
```bash
./scripts/deploy.sh [patch | minor | major | <version>]
```

### Safety Flags
- **Dry Run (Testing):** `./scripts/deploy.sh [bump] --dry-run` (executes pre-flight, version calculation, static analysis, unit tests, and build, but skips remote push and GitHub publishing).
- **Local Packaging Only:** `./scripts/deploy.sh [bump] --no-push` (builds and commits locally without pushing to GitHub).

### Invariants Enforced by Protocol
1. **Version Synchronization:** `pubspec.yaml` and `lib/core/constants/app_constants.dart` must always match (tested via `test/unit/app_version_test.dart`).
2. **Anti-404 Windows Badge Rule:** On `README.md`, if the new release is macOS-only, never link the Windows badge to `/releases/latest/download/...`. Always pin the last known valid Windows release tag to prevent HTTP 404 errors.
3. **No Unverified Claims:** Release notes (`docs/releases/v<version>.md`) must strictly document verified features present in code.
4. **Zero-Warning Gate:** Build will stop immediately if `flutter analyze` reports any issue or any test fails.

### Reference Runbook
- [.agents/skills/deploy-release/SKILL.md](.agents/skills/deploy-release/SKILL.md)
- [docs/release-guide.md](docs/release-guide.md)
