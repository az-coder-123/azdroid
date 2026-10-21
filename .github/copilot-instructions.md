# GitHub Copilot Instructions — Azdroid

When contributing code or responding to tasks in the Azdroid repository:

1. **Engineering Guidelines:** Adhere strictly to [AGENTS.md](../AGENTS.md). Enforce SRP (< 250 lines per file/widget), platform isolation ([docs/platform-abstraction.md](../docs/platform-abstraction.md)), and exclusive `flutter_bloc` state management.
2. **Quality Standards:** All code must pass `dart format .`, `flutter analyze` (zero issues), and `flutter test` (100% pass).
3. **Automated Releases:** For any release or deployment requests, follow the protocol in `AGENTS.md` Section 10 and execute `./scripts/deploy.sh [patch|minor|major]`. Never perform manual unverified bumps or create 404 links on `README.md`.
