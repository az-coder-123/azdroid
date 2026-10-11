# AI Assistant Guidelines & Development Standards (AGENTS.md)

This document defines the mandatory engineering standards, architectural rules, and operational workflows for all AI assistants (e.g., Antigravity, Claude, Copilot, Cursor) and automated agents contributing to the **WifiDesk** project.

---

## 🎯 1. Architectural Principles: Modular & Feature-Driven Design

1. **Feature-First / Modular Structure:**
   - Organize code primarily by **feature**, not solely by layer. Each feature must be self-contained in `lib/features/<feature_name>/`:
     ```text
     lib/
     ├── core/               # Shared utilities, constants, theme, networking, platform helpers
     │   ├── constants/
     │   ├── network/
     │   ├── services/
     │   └── theme/
     ├── features/           # Modular domain features
     │   ├── discovery/      # mDNS device discovery & pairing
     │   ├── streaming/      # Video decoding, H.264 rendering, texture management
     │   ├── control/        # Mouse, keyboard, and touch event injection
     │   └── settings/       # Bitrate, resolution, and preference management
     └── main.dart           # App entry point & dependency injection initialization
     ```
2. **Clear Layering within Modules:**
   - **Data Layer:** Remote/local data sources, repository implementations, low-level socket clients, platform channel invocations.
   - **Domain Layer:** Pure business logic, entity models, and abstract repository contracts (free of UI framework dependencies).
   - **Presentation Layer:** Widgets, UI views, and State Management (Cubits/BLoCs).
3. **Decoupled Dependencies:**
   - Never tightly couple features to one another. Use abstract interfaces and constructor injection (or dependency containers like `get_it`) to promote testability.

---

## ⚡️ 2. State Management Standard: Cubit / BLoC

1. **Exclusive State Management Choice:**
   - All presentation logic and asynchronous states must be managed using the **`flutter_bloc`** ecosystem (`Cubit` or `Bloc`).
   - Use `Cubit` for straightforward synchronous/asynchronous state transitions.
   - Use `Bloc` when event debouncing, throttling, or complex reactive event streams are required (e.g., high-frequency socket input events).
2. **Predictable & Immutable States:**
   - All state classes must be immutable (using `Equatable` or `@freezed`).
   - Always represent explicit UI states: `Initial`, `Loading`, `Success`, and `Failure` (with clear error messages/objects).
3. **Clean UI Separation:**
   - Widgets must remain purely declarative. Business logic, timers, network requests, and socket listeners belong strictly inside Cubits/BLoCs or background services.

---

## 🧼 3. Clean Code & Engineering Standards

1. **Adherence to SOLID & Clean Code:**
   - **Single Responsibility Principle (SRP):** Each class, function, and file must have one single, well-defined responsibility. Keep files compact (< 250 lines where practical).
   - **Don't Repeat Yourself (DRY):** Extract duplicated logic into reusable domain helpers, shared extension methods, or core utilities.
   - **Open/Closed & Dependency Inversion:** Depend upon abstractions, not concrete implementations.
2. **Zero Hardcoding Policy:**
   - **No magic numbers or strings:** Extract all constants into structured files (e.g., `AppConstants`, `SocketConfig`, `ThemeConstants`).
   - Extract UI spacing, paddings, timeouts, and default ports into descriptive constants.
3. **Error Handling:**
   - Handle exceptions at boundaries (e.g., socket disconnections, ADB command failures). Never leave empty `catch` blocks or swallow exceptions silently.

---

## 🧪 4. Comprehensive Test Coverage

Every new feature, bug fix, or refactor must be accompanied by thorough tests:

1. **Unit Tests:**
   - Test data models, serialization, business logic, and utility functions in `test/unit/`.
2. **BLoC / State Tests:**
   - Use `bloc_test` to verify expected state emission sequences for every Cubit and BLoC in `test/bloc/`.
3. **Widget & Smoke Tests:**
   - Test UI components and verify state rendering under various states (loading, error, empty, active).
4. **Mocking:**
   - Use `mocktail` or `mockito` to stub external network, process, or platform channel calls. Tests must execute independently without requiring a physical Android device or active Wi-Fi connection.

---

## 🔍 5. Verification Protocol: Zero-Warning Policy

Before concluding any task or generating a commit, AI assistants must strictly execute this verification cycle:

1. **Static Analysis Enforcement:**
   ```bash
   flutter analyze
   ```
   - **Zero-Tolerance Rule:** Every warning, error, and linter suggestion must be completely resolved. Do not ignore deprecation warnings or analysis hints.
2. **Test Suite Execution:**
   ```bash
   flutter test
   ```
   - All existing and new tests must pass with 100% success rate.
3. **Format & Consistency:**
   ```bash
   dart format .
   ```
   - Ensure clean formatting conforming to the standard Dart style guide.

---

## 📚 6. Documentation Synchronization

1. **Real-Time Documentation Updates:**
   - Whenever code changes modify user-facing behaviors, architectural patterns, APIs, or project dependencies, the corresponding documentation (`README.md`, `docs/*.md`) **must be updated in the same commit/turn**.
   - Keep code docstrings, parameter descriptions, and return types accurate and up to date.
2. **No Stale Information:**
   - Remove obsolete references or deprecated workflows immediately.

---

## ✍️ 7. Language & Communication Standards

1. **Professional & Simple English:**
   - All documentation, pull requests, commit messages, code comments, and docstrings must be written exclusively in **professional, concise, and plain English**.
2. **Clarity Over Complexity:**
   - Write clear and direct explanations. Avoid unnecessarily verbose sentences or overly dense jargon.
3. **Standardized Commit Format (Conventional Commits):**
   - Format all Git commit messages cleanly:
     - `feat: ...` for new features
     - `fix: ...` for bug fixes
     - `refactor: ...` for code refactoring without behavior change
     - `docs: ...` for documentation updates
     - `test: ...` for adding or updating tests
