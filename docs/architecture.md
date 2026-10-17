# DeskDroid — Modular Architecture Documentation

> Technical blueprint and design patterns implemented in **DeskDroid** adhering to Clean Architecture, SOLID principles, and strict modular feature boundaries.

---

## 🏛️ High-Level Architectural Pattern

DeskDroid follows a **Feature-Driven Clean Architecture** powered by the **BLoC / Cubit** reactive state management pattern.

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
│   ├── constants/                          # Zero-hardcoding constants (incl. AdbTimeouts, FeedbackDurations)
│   │   ├── android_key_codes.dart          # Android KeyEvent codes & Flutter key mapper
│   │   ├── app_constants.dart              # App metadata, dimensions
│   │   ├── audio_constants.dart            # Audio sample rate, channels, codec defaults
│   │   ├── control_constants.dart          # Pointer, swipe, and scroll parameters
│   │   ├── productivity_constants.dart     # Clipboard sync & file transfer parameters
│   │   └── socket_config.dart              # Network ports, timeouts
│   ├── di/                                 # Dependency Injection container
│   │   ├── modules/                        # Feature-scoped DI registration modules
│   │   └── injection.dart                  # Modular service locator entrypoint (GetIt)
│   ├── services/                           # System process & native bridge services
│   │   ├── adb_service.dart                # ADB CLI & mDNS daemon controller
│   │   ├── network_info_service.dart       # Host machine Wi-Fi IPv4 address resolution
│   │   ├── process_executor.dart           # Testable process runner abstraction
│   │   └── video_stream_native_service.dart # Native video plugin bridge (VideoToolbox / Media Foundation)
│   └── theme/                              # Apple-native design system tokens
│       ├── app_colors.dart                 # Dark Mode color palette
│       ├── app_typography.dart             # Apple system font styles
│       └── app_theme.dart                  # Material3 ThemeData (macOS & Windows)
├── features/                               # Modular domain features
│   ├── discovery/                          # Device discovery & wireless pairing
│   │   ├── domain/
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
│   │       ├── widgets/empty_state/
│   │       │   ├── empty_state_radar_icon.dart
│   │       │   ├── empty_state_step_card.dart
│   │       │   └── usb_quick_switch_banner.dart
│   │       ├── widgets/device_card.dart
│   │       ├── widgets/device_status_badge.dart
│   │       ├── widgets/discovery_app_bar_actions.dart
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
│   ├── audio/                              # Low-latency raw Opus/PCM audio forwarding
│   │   ├── domain/
│   │   │   ├── entities/audio_stream_entity.dart
│   │   │   └── repositories/audio_repository.dart
│   │   ├── data/
│   │   │   ├── datasources/audio_socket_datasource.dart
│   │   │   └── repositories/audio_repository_impl.dart
│   │   └── presentation/
│   │       ├── cubit/audio_cubit.dart
│   │       ├── cubit/audio_state.dart
│   │       └── widgets/audio_controls_widget.dart
│   ├── menubar/                            # Menu Bar companion state (popover not wired yet)
│   │   ├── domain/
│   │   │   └── entities/menu_bar_status_entity.dart
│   │   └── presentation/
│   │       ├── cubit/menu_bar_cubit.dart
│   │       ├── cubit/menu_bar_state.dart
│   │       └── widgets/menu_bar_companion_popover.dart
│   ├── guide/                              # User handbook & split guide modal (SRP)
│   │   ├── domain/models/guide_category.dart
│   │   └── presentation/widgets/
│   │       ├── components/                 # Atomic UI elements (< 100 lines each)
│   │       │   ├── guide_callout.dart
│   │       │   ├── guide_card.dart
│   │       │   ├── guide_command_snippet.dart
│   │       │   ├── guide_faq_item.dart
│   │       │   ├── guide_feature_bullet.dart
│   │       │   ├── guide_gesture_item.dart
│   │       │   ├── guide_section_header.dart
│   │       │   ├── guide_shortcut_item.dart
│   │       │   └── guide_step_row.dart
│   │       ├── sections/                   # Modular guide chapters (< 120 lines each)
│   │       │   ├── controls_section.dart
│   │       │   ├── productivity_section.dart
│   │       │   ├── quick_start_section.dart
│   │       │   ├── troubleshooting_section.dart
│   │       │   └── xiaomi_setup_section.dart
│   │       ├── guide_sidebar.dart
│   │       └── user_guide_dialog.dart
│   ├── apk_installer/                      # Professional APK inspection & sideloading
│   │   ├── domain/
│   │   │   ├── entities/apk_metadata_entity.dart
│   │   │   └── repositories/apk_installer_repository.dart
│   │   ├── data/
│   │   │   ├── datasources/aapt2_metadata_datasource.dart
│   │   │   └── repositories/apk_installer_repository_impl.dart
│   │   └── presentation/
│   │       ├── cubit/apk_installer_cubit.dart
│   │       ├── cubit/apk_installer_state.dart
│   │       └── widgets/apk_installer_dialog.dart
│   ├── logging/                            # Real-time device logcat streaming & debugging
│   │   ├── domain/
│   │   │   ├── entities/device_log_entry.dart
│   │   │   ├── entities/log_filter_criteria.dart
│   │   │   ├── entities/log_filter_preset.dart
│   │   │   ├── entities/log_level.dart
│   │   │   └── repositories/device_log_repository.dart
│   │   ├── data/
│   │   │   ├── datasources/logcat_stream_datasource.dart
│   │   │   └── repositories/device_log_repository_impl.dart
│   │   └── presentation/
│   │       ├── cubit/device_log_cubit.dart
│   │       ├── cubit/device_log_state.dart
│   │       └── widgets/
│   │           ├── device_log_dialog.dart
│   │           ├── log_action_footer.dart
│   │           ├── log_console_row.dart
│   │           ├── log_console_table.dart
│   │           ├── log_detail_drawer.dart
│   │           ├── log_exclude_tags_bar.dart
│   │           ├── log_filter_bar.dart
│   │           ├── log_level_chip.dart
│   │           ├── log_pid_dropdown_menu.dart
│   │           ├── log_pid_filter_input.dart
│   │           ├── log_preset_dropdown.dart
│   │           ├── log_stack_trace_view.dart
│   │           ├── log_tag_dropdown_menu.dart
│   │           └── log_tag_filter_input.dart
│   └── settings/                           # User preferences & stream quality
│       └── domain/entities/app_settings_entity.dart
└── main.dart                               # Entrypoint with DI & MultiBlocProvider
```

### Native Platform Code (outside `lib/`)

```text
macos/Runner/
├── ScrcpyStreamPlugin.swift                # VideoToolbox decoder + texture (com.deskdroid/video_stream)
└── ScrcpyStreamStats.swift                 # getStats state & counters
windows/scrcpy_stream/                      # Media Foundation decoder plugin (same channel contract)
native/scrcpy_core/                         # Platform-neutral C++17: scrcpy parsing, NV12 conversion, stats
scripts/
├── build_release.sh                        # macOS release ZIP
└── build_release.ps1                       # Windows release ZIP
```

Both plugins implement [native-video-contract.md](native-video-contract.md). Dart-side platform differences are covered in [platform-abstraction.md](platform-abstraction.md); feature status per platform in [platform-support.md](platform-support.md).

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
   - All components are registered through the `GetIt` service locator in `lib/core/di/injection.dart`. Cross-feature rules (shared kernel, composition root, core contracts) live in [dependency-boundaries.md](dependency-boundaries.md).
4. **Comprehensive Automated Testing:**
   - **Unit Tests:** Data serialization and model mapping in `test/unit/`.
   - **BLoC Tests:** Cubit state transitions verified with `bloc_test` in `test/bloc/`.
   - **Widget Tests:** UI layout, button interactions, and state rendering in `test/widget/`.
5. **Universal UI Responsiveness & Zero-Overflow Policy:**
   - All desktop viewports, modal dialogs, overlays, and sidebars defensively adapt to arbitrary window resizing, compact laptop screens, and 4K/5K displays using `LayoutBuilder`, `FittedBox`, scrollable containers, and bounded constraint envelopes with zero `RenderFlex` overflows.

