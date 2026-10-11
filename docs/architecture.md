# WifiDesk — Modular Architecture Documentation

> Technical blueprint and design patterns implemented in **WifiDesk** adhering to Clean Architecture, SOLID principles, and strict modular feature boundaries.

---

## 🏛️ High-Level Architectural Pattern

WifiDesk follows a **Feature-Driven Clean Architecture** powered by the **BLoC / Cubit** reactive state management pattern.

```mermaid
flowchart TD
    subgraph Presentation ["Presentation Layer"]
        UI["Widgets / Pages (Stateless / Pure Declarative)"]
        Cubit["Cubits / Blocs (State Management)"]
        State["Immutable States (Equatable)"]
        UI -->|Dispatches Actions| Cubit
        Cubit -->|Emits New States| State
        State -->|Rebuilds View| UI
    end

    subgraph Domain ["Domain Layer (Pure Business Logic)"]
        Entities["Entities (Business Objects)"]
        RepoContract["Repository Interfaces (Contracts)"]
        Cubit -->|Invokes| RepoContract
        RepoContract -.->|Returns| Entities
    end

    subgraph Data ["Data Layer (Infrastructure & I/O)"]
        RepoImpl["Repository Implementations"]
        DataSources["Data Sources (ADB, Sockets, Discovery)"]
        Models["Data Transfer Objects (DTOs / Models)"]
        RepoContract <|.. RepoImpl
        RepoImpl --> DataSources
        DataSources --> Models
    end

    subgraph Core ["Core Foundation"]
        DI["Service Locator (GetIt)"]
        Constants["AppConstants & SocketConfig"]
        Theme["Design Tokens (Colors, Typography, Themes)"]
    end

    DI -.->|Injects Dependencies| Presentation
    DI -.->|Injects Dependencies| Data
```

---

## 📁 Directory Structure Breakdown

```text
lib/
├── core/                                   # Shared kernel & infrastructure
│   ├── constants/                          # Zero-hardcoding constants
│   │   ├── android_key_codes.dart          # Android KeyEvent codes & Flutter key mapper
│   │   ├── app_constants.dart              # App metadata, dimensions
│   │   ├── control_constants.dart          # Pointer, swipe, and scroll parameters
│   │   ├── productivity_constants.dart     # Clipboard sync & file transfer parameters
│   │   └── socket_config.dart              # Network ports, timeouts
│   ├── di/                                 # Dependency Injection container
│   │   └── injection.dart                  # Service locator configuration (GetIt)
│   ├── services/                           # System process & native bridge services
│   │   ├── adb_service.dart                # ADB CLI & mDNS daemon controller
│   │   └── process_executor.dart           # Testable process runner abstraction
│   └── theme/                              # Apple-native design system tokens
│       ├── app_colors.dart                 # macOS Dark Mode color palette
│       ├── app_typography.dart             # Apple system font styles
│       └── app_theme.dart                  # Material3 ThemeData for macOS
├── features/                               # Modular domain features
│   ├── discovery/                          # Device discovery & wireless pairing
│   │   ├── domain/
│   │   │   ├── entities/device_entity.dart
│   │   │   └── repositories/device_discovery_repository.dart
│   │   ├── data/
│   │   │   ├── models/device_model.dart
│   │   │   ├── datasources/device_discovery_datasource.dart
│   │   │   └── repositories/device_discovery_repository_impl.dart
│   │   └── presentation/
│   │       ├── cubit/discovery_cubit.dart
│   │       ├── cubit/discovery_state.dart
│   │       ├── cubit/pairing_cubit.dart
│   │       ├── cubit/pairing_state.dart
│   │       ├── widgets/device_card.dart
│   │       ├── widgets/empty_state_view.dart
│   │       ├── widgets/manual_connect_dialog.dart
│   │       ├── widgets/pairing_dialog.dart
│   │       └── pages/discovery_page.dart
│   ├── streaming/                          # Low-latency H.264 video pipeline
│   │   ├── domain/
│   │   │   ├── entities/stream_session_entity.dart
│   │   │   └── repositories/streaming_repository.dart
│   │   ├── data/
│   │   │   ├── datasources/scrcpy_server_manager.dart
│   │   │   ├── datasources/streaming_socket_datasource.dart
│   │   │   └── repositories/streaming_repository_impl.dart
│   │   └── presentation/
│   │       ├── cubit/streaming_cubit.dart
│   │       ├── cubit/streaming_state.dart
│   │       ├── widgets/floating_controls_toolbar.dart
│   │       ├── widgets/stream_telemetry_header.dart
│   │       ├── widgets/video_display_viewport.dart
│   │       └── pages/mirroring_page.dart
│   ├── control/                            # Input normalization & pointer injection
│   │   ├── domain/
│   │   │   ├── entities/input_event_entity.dart
│   │   │   └── repositories/control_repository.dart
│   │   ├── data/
│   │   │   ├── datasources/control_datasource.dart
│   │   │   └── repositories/control_repository_impl.dart
│   │   └── presentation/
│   │       ├── bloc/control_bloc.dart
│   │       ├── bloc/control_event.dart
│   │       ├── bloc/control_state.dart
│   │       ├── widgets/input_gesture_viewport_overlay.dart
│   │       ├── widgets/quick_text_input_dialog.dart
│   │       └── widgets/touch_indicator_overlay.dart
│   ├── productivity/                       # Clipboard sync & drag-and-drop transfers
│   │   ├── domain/
│   │   │   ├── entities/clipboard_item_entity.dart
│   │   │   ├── entities/file_transfer_entity.dart
│   │   │   ├── repositories/clipboard_repository.dart
│   │   │   └── repositories/file_transfer_repository.dart
│   │   ├── data/
│   │   │   ├── datasources/clipboard_datasource.dart
│   │   │   ├── datasources/file_transfer_datasource.dart
│   │   │   ├── repositories/clipboard_repository_impl.dart
│   │   │   └── repositories/file_transfer_repository_impl.dart
│   │   └── presentation/
│   │       ├── cubit/clipboard_cubit.dart
│   │       ├── cubit/clipboard_state.dart
│   │       ├── cubit/file_transfer_cubit.dart
│   │       ├── cubit/file_transfer_state.dart
│   │       ├── widgets/clipboard_sync_menu_button.dart
│   │       ├── widgets/file_drop_target_overlay.dart
│   │       └── widgets/transfer_status_banner.dart
│   └── settings/                           # User preferences & stream quality
│       └── domain/entities/app_settings_entity.dart
└── main.dart                               # Entrypoint with DI & MultiBlocProvider
```

---

## ⚙️ Key Engineering Tenets

1. **Strict Separation of Concerns (SRP):**
   - Widgets contain **zero business logic**; they only render states emitted by Cubits.
   - Domain layer has **zero Flutter UI dependencies**, ensuring pure testability.
2. **Predictable State Management:**
   - Every state transition is explicit and modeled with sealed classes (`DiscoveryInitial`, `DiscoveryLoading`, `DiscoveryLoaded`, `DiscoveryError`).
   - States are immutable and compared using `Equatable`.
3. **Dependency Inversion (DIP):**
   - High-level modules (Cubits) depend on domain abstractions (`DeviceDiscoveryRepository`), not low-level concrete implementations.
   - All components are registered through the `GetIt` service locator in `lib/core/di/injection.dart`.
4. **Comprehensive Automated Testing:**
   - **Unit Tests:** Data serialization and model mapping in `test/unit/`.
   - **BLoC Tests:** Cubit state transitions verified with `bloc_test` in `test/bloc/`.
   - **Widget Tests:** UI layout, button interactions, and state rendering in `test/widget_test.dart`.
