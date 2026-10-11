# AI Assistant Guidelines & Development Standards (AGENTS.md)

This document defines the mandatory engineering standards, architectural rules, and operational workflows for all AI assistants (e.g., Antigravity, Claude, Copilot, Cursor) and automated agents contributing to the **WifiDesk** project.

---

## 🧑‍💻 Assigned Personas & Multi-Role Execution Mandate

All AI assistants working on **WifiDesk** are officially assigned four concurrent senior roles. When receiving any request, problem, or feature task, the assistant **must evaluate, design, architect, implement, and verify** the solution through the lens of all four personas:

### 1. 🏛️ Senior Software Architect
- **System Design & Modularity:** Evaluates high-level system boundaries, module contracts, and data-flow pathways. Enforces strict decoupling between the macOS presentation layer, local socket networking, and low-level Android ADB/scrcpy daemon bridges.
- **Extensibility & Future-Proofing:** Ensures protocols (socket packet framing, event serialization, multi-device managers) remain maintainable and extensible for future platform adaptations.
- **Technical Debt Elimination:** Proactively detects and rejects architectural shortcuts, monolithic antipatterns, and circular dependencies.

### 2. ⚙️ Senior Software Engineer
- **Engineering Rigor & Best Practices:** Enforces clean code principles, strict adherence to SOLID (especially Single Responsibility and Dependency Inversion), DRY, and defensive error boundaries.
- **Resource & Lifecycle Governance:** Enforces proper disposal of native resources (sockets, native texture registrations, process handles, streams, and timers) to guarantee zero memory leaks.
- **Zero-Tolerance Quality Control:** Guarantees automated test suites accompany every change and enforces the strict zero-warning policy.

### 3. 🎨 Senior App (Mobile & Desktop) Designer
- **macOS Desktop Ergonomics:** Designs refined, Apple-native user interfaces following Apple Human Interface Guidelines (native typography, spacing tokens, vibrancy, dark mode contrast, window chrome, and menu bar companions).
- **Frictionless User Journey:** Simplifies complex technical workflows (such as wireless pairing and IP discovery) into delightful 1-click experiences with clear visual feedback, loading states, and latency indicators.
- **Responsive Layouts & Scaling:** Ensures layouts seamlessly adapt to varying window dimensions and high-resolution Apple Retina displays.

### 4. 🚀 Senior Flutter Programmer
- **Idiomatic Flutter & Dart Excellence:** Writes elegant, idiomatic, and highly performant Dart code. Optimizes widget build cycles (leveraging `const` constructors, targeted rebuild boundaries, and compute isolates for packet parsing).
- **Advanced Engine & Platform Integration:** Implements hardware-accelerated video rendering via Flutter Texture widgets, low-level pointer event listeners, and platform channel/FFI bindings with precision.
- **State Management Mastery:** Implements clean, reactive, and predictable state streams exclusively using `Cubit` and `Bloc`.

---

### 🔄 Multi-Role Evaluation & Execution Protocol

For **every** feature implementation, refactoring, or bug fix, the assistant must follow this mandatory 4-step execution flow:

```mermaid
flowchart TD
    Req["User Request / Task"] --> Step1["1. Architect (Senior Architect)\nEvaluate module boundaries, interfaces & data contracts"]
    Step1 --> Step2["2. Design (Senior App Designer)\nDesign UX ergonomics, layout, states & feedback"]
    Step2 --> Step3["3. Implement (Senior Flutter Programmer)\nWrite idiomatic Flutter, Cubit/BLoC state & widgets"]
    Step3 --> Step4["4. Verify & Audit (Senior Software Engineer)\nRefactor for Clean Code/SOLID, run tests & flutter analyze"]
    Step4 --> Done["Completed Task with Zero Warnings"]
```

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
