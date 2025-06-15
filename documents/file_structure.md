# Current State (April 2024)

- Error handling is now fully centralized via UserFacingError in both MainApp and ShareExtension.
- All user-facing errors are localized (en/ru) and provide actionable advice.
- Alert logic in ShareExtensionView is improved for reliability and user experience.
- Logging uses English messages for consistency across modules.
- Tests cover all error branches, including race conditions between error and timeout.
- FetchError and UserFacingError have been refactored and relocated for clarity.
- All changes are covered by unit and UI tests; project is stable and up to date.

# Craftify File Structure

---

## Overview
- Describes project org, key files/dirs, targets, schemes

## Directory
```mermaid
graph TD
  A[Root]
  A --> B[run (CLI)]
  A --> C[Project.swift (Tuist)]
  A --> D[.github/ (CI/CD)]
  A --> E[build/ (artifacts)]
  A --> F[documents/ (docs)]
  A --> G[Craftify.xcodeproj/ (gen Xcode)]
  A --> H[Configs/ (configs)]
  A --> I[src/ (code/tests)]
  I --> J[Common/]
  I --> K[MainApp/]
  I --> L[ShareExtension/]
```

## Key Files/Folders
| Name                | Purpose                        |
|---------------------|-------------------------------|
| run                 | Main CLI script                |
| Project.swift       | Tuist manifest                 |
| .github/            | CI/CD workflows                |
| build/              | Build artifacts                |
| documents/          | Docs (reqs, manuals, arch, etc)|
| Craftify.xcodeproj/ | Gen Xcode proj (by Tuist)      |
| Configs/            | Extra configs                  |
| src/                | All code/tests                 |

### src/Common/
- **Sources/**: Shared logic, models, utils (AppSettingsManager, LogManagerShared, ops)
  - AuthManager.swift: Keychain API key
  - LogManagerShared.swift: logging
  - Masking.swift: key masking
  - Models/: data models (ResultMode, OperationType, etc.)
  - InventoryOperation.swift: op model (colorHex, resultMode)
  - InventoryManager.swift: inventory mgmt (colorHex, resultMode)
  - CorrectParams.swift: correct op params
  - TextFetcher/: load/extract text from URL
  - OperationInput.swift: URL/text fields for ops
  - SummarizeOperation.swift: uses TextFetcher, AppSettingsManager.shared.nativeLanguage
  - CraftifyButtonConstants.swift: btn style consts
  - GraySecondaryButtonStyle.swift: gray secondary button style
  - ColorPaletteConstants.swift: color palette consts
  - SupportedLanguages.swift: all supported langs
  - AppSettingsManager.swift: settings, logs
- **UnitTests/**: tests for all logic
- **Config/**: SPM target config
- **Resources/**: l10n
- **Generated/**: SwiftGen l10n code

### src/MainApp/
- **Sources/**: Main app (SwiftUI views, VMs, UI logic)
- **UnitTests/**: tests for MainApp logic
- **Config/**: app config/entitlements
- **Resources/**: l10n, assets

### src/ShareExtension/
- **Sources/**: ShareExt (text proc, AppSettingsManager via App Group)
- **UnitTests/**: tests for ShareExt logic
- **Config/**: ext config/entitlements
- **Resources/**: assets, l10n

## Targets/Schemes
- MainApp
- MainAppUnitTests
- ShareExtension
- ShareExtensionUnitTests
- CommonUnitTests
- ShareExtensionSizeReport

## Logging
- All logs: Unified Log (os_log, subsystem: Internal)
- View: `./run logs` (filter: Internal, MainApp, ShareExt)
- No export

## Testing/Isolation
- All test files/deps: only in UnitTests, only in UnitTest targets
- Prevents test libs in prod builds

## Key files/dirs
| Name              | Purpose                        |
|-------------------|-------------------------------|
| Project.swift     | Tuist manifest                 |
| Workspace.swift   | Tuist workspace                |
| src/              | code, resources, tests         |
| build/            | build artifacts                |
| Configs/          | xcconfig files                 |
| documents/        | docs, arch                     |
| .swiftlint.yml    | SwiftLint config               |
| .swiftformat      | SwiftFormat config             |
| .swiftgen.yml     | SwiftGen config                |

# src/
- Common/: shared logic, models, utils (AppSettingsManager, LogManagerShared, ops)
- MainApp/: main app (SwiftUI, VMs, UI)
- ShareExtension/: ShareExt (text proc, AppSettingsManager)

## Patterns
- Centralized settings, no param duplication
- All ViewModels: only AppSettingsManager
- All buttons: centralized palette
- Test deps: only in UnitTests, only in UnitTest targets

# Project root
run                  # Main CLI script for all project operations
Project.swift        # Tuist project manifest
dockerfile           # Docker build file
README.md            # Project overview and instructions
.swiftlint.yml       # SwiftLint configuration
.swiftformat         # SwiftFormat configuration
.swiftgen.yml        # SwiftGen configuration

# Key folders
.github/             # GitHub Actions and CI/CD workflows
.cursor/             # Cursor editor config and state
build/               # Build artifacts (generated)
documents/           # Project documentation (requirements, manuals, architecture, etc.)
Craftify.xcodeproj/  # Xcode project directory (generated by Tuist, not tracked)
Configs/             # Additional configuration files
src/                 # All source code and tests (see below)

src/
  Common/            # Shared business logic, models, and utilities (used by app and extension), including AppSettingsManager, LogManagerShared, and operations (Summarize, Explain, etc.)
    Sources/
      AuthManager.swift         # Keychain API key management
      LogManagerShared.swift    # Centralized logging
      Masking.swift            # Key masking utilities
      Models/                  # Shared data models
        ResultMode.swift           # Режим обработки результата (clipboard/display)
        OperationType.swift        # Протокол операций с resultMode
        ExplainOperation.swift     # Операция Explain с режимом display
        ...
      InventoryOperation.swift      # Модель операции, теперь с colorHex и поддержкой resultMode
      InventoryManager.swift        # Управление инвентарём, поддержка colorHex и resultMode
      CorrectParams.swift           # Параметры операции correct (без stylePreservationLevel)
      TextFetcher/                 # Module for loading and extracting text from URL
        TextFetching.swift         # Protocol for loading text
        SwiftSoupTextFetcher.swift # Implementation using SwiftSoup and URLSession
      OperationInput.swift         # Added fields `url: String?`, `text: String?` for passing URL or text in operations, not containing nativeLanguage
      SummarizeOperation.swift     # Integration with TextFetcher, asynchronous text retrieval by URL, uses AppSettingsManager.shared.nativeLanguage
      CraftifyButtonConstants.swift # Единые константы для стилей кнопок (цвета, радиус, отступы, масштаб)
      GraySecondaryButtonStyle.swift  # Серый вторичный стиль кнопок (используется для Cancel в формах)
      ColorPaletteConstants.swift   # Единые константы для палитры цветов операций (размеры, список цветов, отступы, маски)
      SupportedLanguages.swift      # Contains the SupportedLanguages structure and a list of all supported languages (ISO-639-1 + artificial), used for language selection in settings and operations.
      AppSettingsManager.swift       # Centralized service for all application settings, stores language and logs changes
    UnitTests/
      AuthManagerTests.swift    # Keychain logic tests
      LogManagerSharedInMemoryTests.swift # Logging tests
      InventoryOperationTests.swift # Unit-тесты для модели с colorHex и resultMode
      InventoryManagerTests.swift   # Unit-тесты сериализации colorHex и resultMode
    Config/
      Info.plist               # SPM target configuration
    Resources/
      en.lproj/Localizable.strings # English localization
      ru.lproj/Localizable.strings # Russian localization
    Generated/
      Strings.swift            # SwiftGen-generated localization code
    Docs/
      SwiftLintFormattingExamples.md # Code style examples
    Styles/                       # Отдельные стили для MainApp UI
      SettingsPrimaryButtonStyle.swift # Стиль кнопки Settings (вторичный фон, основной текст)

  MainApp/           # Main iOS application (SwiftUI views, view models, UI logic), uses AppSettingsManager for access to settings
    Sources/
      CraftifyApp.swift         # App entry point
      HomeView.swift            # Main inventory screen
      SettingsView.swift        # API key and settings UI
      HowToUseView.swift        # Onboarding UI
      AddOperationView.swift    # Add operation UI
      EditOperationView.swift   # Edit operation UI
      InventoryOperation.swift      # Модель операции, теперь с colorHex и resultMode
      InventoryManager.swift        # Управление инвентарём, поддержка colorHex и resultMode
    UnitTests/
      HomeViewModelTests.swift  # Inventory logic tests
      SettingsViewModelTests.swift # Settings logic tests
      InventoryOperationTests.swift # Unit-тесты для модели с colorHex и resultMode
      InventoryManagerTests.swift   # Unit-тесты сериализации colorHex и resultMode
    Config/
      Info.plist                # App configuration
      Craftify.entitlements      # App entitlements
    Resources/
      LaunchScreen.storyboard    # Launch screen
      en.lproj/Localizable.strings # English localization
      ru.lproj/Localizable.strings # Russian localization
      Generated/Strings.swift    # SwiftGen-generated localization code

  ShareExtension/    # Share Extension for text processing from other apps, uses AppSettingsManager through App Group
    Sources/
      ShareExtensionManager.swift   # Reads inventory, API key, triggers processing (учитывает resultMode)
      ProcessingManager.swift       # Handles text processing logic
      LLMAPIClient.swift            # OpenAI API client
      ClipboardManager.swift        # Clipboard integration
      ShareExtensionView.swift      # SwiftUI UI for extension (поддержка display/clipboard)
      ShareExtensionViewController.swift # Hosting controller
    UnitTests/
      ShareExtensionManagerTests.swift # Manager logic tests (режимы clipboard/display)
      LLMAPIClientTests.swift          # API client tests
    Config/
      Info.plist                # Extension configuration
      ShareExtension.entitlements # Extension entitlements
    Resources/
      Assets.xcassets/           # Extension assets
      Placeholder.txt            # Placeholder resource
    # Важно: поддержка активации по тексту и URL (public.text, public.url) задаётся через NSExtensionActivationRule in Project.swift (Tuist)
    # Оба типа обрабатываются как текст, приоритет у текста.

## Targets and Schemes
- MainApp
- ShareExtension
- ShareExtensionSizeReport

## Logging
- Все логи пишутся через Unified Log (os_log, subsystem: Internal, только message + metadata).
- Просмотр логов: ./run logs (фильтрация по subsystem Internal, MainApp и ShareExtension, все уровни).
- Экспорт логов не поддерживается.

- `src/ShareExtension/Sources/ShareExtensionView.swift` — основной UI-компонент окна шаринга, реализует разметку, закрепление кнопки закрытия, скроллирование и оверлеи.

- `src/Common/Sources/CraftifyButtonConstants.swift` — единые константы для стилей кнопок (цвета, радиус, отступы, масштаб).
- `src/Common/Sources/ColorPaletteConstants.swift` — единые константы для палитры цветов операций (размеры, список цветов, отступы, маски).

- Все тестовые файлы и тестовые зависимости (например, ViewInspector, XCTest) должны находиться только в папках UnitTests и подключаться только в UnitTest targets.
- Это предотвращает попадание тестовых библиотек в production-сборки MainApp и ShareExtension.

## File Organization Patterns
- Все настройки централизованы, нет дублирования полей языка в параметрах операций.
- Логирование изменений настроек ведётся централизованно через LogManagerShared.
- Все ViewModel'и используют только AppSettingsManager для доступа к настройкам.
- Все кнопки используют централизованную палитру для цвета текста и фона через Environment. Цвет текста задается явно в вызывающем коде.