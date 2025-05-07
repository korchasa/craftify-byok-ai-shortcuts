# Craftify Implementation & Technology Stack

---

## Technology Stack
- Swift 5.7+
- SwiftUI
- XcodeGen
- SwiftPM (Common, LogManagerShared)
- SwiftGen (localization)
- GitHub Actions (CI/CD)
- SwiftSoup (HTML parsing)
- URLSession (networking)
- TDD (unit tests for all error branches)
- Поддержка всех языков ISO-639-1 и ряда искусственных языков (Klingon, Sindarin, Quenya, Lojban, Toki Pona, Interlingua, Dothraki, Valyrian, Na'vi) через структуру SupportedLanguages
- Для промптов LLM всегда используется английское название языка (englishName)

## Environment Setup
1. Clone the repository.
2. Install dependencies: run `./run init` (installs all CLI tools via Homebrew).
3. Generate the project: `./run generate` (uses tuist generate and swiftgen).
4. Build and run: `./run deploy:simulator`.
5. For tests: `./run check`.

## CLI Tools

| Tool           | Version   | Purpose                          |
|----------------|-----------|----------------------------------|
| Tuist          | latest    | Generate Xcode project           |
| SwiftLint      | 0.59.1   | Swift style analyzer             |
| SwiftFormat    | 0.55.5   | Swift code formatter             |
| xcbeautify     | 2.28.0   | Beautiful output for xcodebuild  |
| swiftgen       | 6.6.3    | Localization code generation     |

All dependencies are installed via `./run init` using Homebrew.

## DevOps and CI/CD
- GitHub Actions is used (`.github/workflows/ci.yml`).
- Caching accelerates builds:
  - DerivedData (`~/Library/Developer/Xcode/DerivedData`)
  - SwiftPM dependencies (`.build`, `.swiftpm`)
- Key cache is built from OS and control files (`Package.resolved`).
- CI/CD checks:
  - Size report: automatic check of ShareExtension size (fail if >20MB)
  - Comment scan: automatic grep for TODO, FIXME, print, debugPrint
  - Build-time metrics: build time and .appex size
  - All checks are integrated into workflow

## API: AuthManager
**Purpose:** Secure storage and retrieval of OpenAI API key via Keychain with Keychain Sharing support (App Group).

**Public Methods:**
| Method | Description |
|--------|-------------|
| `getAPIKey() async throws -> String?` | Retrieve API key (or nil if not found) |
| `setAPIKey(_ key: String) async throws` | Save API key (length validated) |
| `deleteAPIKey() async throws` | Delete API key |
| `maskedAPIKey(_ key: String?) -> String` | Masks the key for logging (example: sk-****abcd) |

- All methods async/await.
- Errors are handled and propagated.
- Masking: only first 3 and last 4 characters are visible.
- For tests — in-memory stub (AuthManagerStub).

## API: LogManagerShared
**Purpose:** Centralized logging for app and extension.

**Public Methods:**
| Method | Description |
|--------|-------------|
| `log(_ entry: LogEntry)` | Write log (system log, os_log) |
| `getLogs() -> [LogEntry]` | No-op in production, only for tests |
| `clearLogs()` | No-op in production, only for tests |
| `exportLogs() throws -> Data` | No-op in production, only for tests |

- In production: only system log, export and FIFO not supported.
- For tests — in-memory implementation with FIFO and export.
- Key masking as in AuthManager.

## Testing
- Unit and UI tests: `./run check`
- Coverage is checked automatically in CI
- All error branches are covered by tests

## Timeout Implementation
- Text processing timeout is implemented only in ShareExtensionViewModel (default 30 seconds, can be overridden in tests via processingTimeoutSeconds).
- ShareExtensionManager does not implement a timeout, only business logic for processing and errors.
- In unit tests, the ViewModel timeout is set via processingTimeoutSeconds.

## Receiving Logs
To view logs, use:
```sh
./run logs
```
The command outputs logs from the unified log (os_log) for the last day, filtering by the subsystem "dev.korchasa.Craftify" in JSON format.

## Operation Color Implementation
- InventoryOperation: added property colorHex (hex color code).
- InventoryManager: supports serialization/deserialization of colorHex.
- AddOperationView/EditOperationView: UI palette for color selection.
- HomeView/ShareExtensionView: displays operation color (indicator).
- Coverage: unit tests (InventoryOperation, InventoryManager), UI tests (Add/EditOperationView).

## Onboarding Flow
- AppState (ObservableObject) with Published consent flag.
- Used via @StateObject in CraftifyApp.
- HowToUseView accepts onConsent callback, called after consent.
- After consent — automatic transition to HomeView.
- Consent is stored via ConsentManager (UserDefaults App Group).

## Project Schemas
- MainApp
- MainAppUnitTests
- ShareExtension
- ShareExtensionUnitTests
- CommonUnitTests
- ShareExtensionSizeReport

## Share Extension UI

```mermaid
graph TD
  ShareExtensionView[ShareExtensionView]
  CloseButton[Close Button (fixed bottom)]
  ScrollView[ScrollView (content)]
  Overlay[Overlay (progress, toast)]
  ShareExtensionView --> ScrollView
  ShareExtensionView --> CloseButton
  ShareExtensionView --> Overlay
  ScrollView -->|contains| Title
  ScrollView -->|contains| Result
  ScrollView -->|contains| OperationsList
```

- The close button is always available at the bottom via `.safeAreaInset`, regardless of content length.
- All other content (title, result, operations) is in a single ScrollView.
- Content is always scrollable if it does not fit on the screen.
- The button does not overlap content, as ScrollView has bottom padding.
- Overlays (progress, toast) are implemented via ZStack and do not interfere with main content interaction.
- All changes are covered by unit and UI tests.

## URL Sharing Support
- Share Extension supports sharing both text (UTType.plainText) and URL (UTType.url).
- If both text and URL are shared, text takes priority.
- Length limit (5000 characters) applies to both text and URL.
- Covered by unit tests.

## Technology Stack and Dependencies
- Swift
- SwiftSoup (HTML parsing)
- URLSession (networking)
- TDD (unit tests for all error branches)

## Development Environment and Setup
- Add SwiftSoup via SPM in project.yml
- All code for text fetching is in src/Common/Sources/TextFetcher
- No manual Xcode configuration required

## Input Handling for Operations
All operations implement an async method `resolveInput(input: OperationInput) -> String`, always called before sending data to LLM:
- **SummarizeOperation**: supports both `text` and `url` (fetches and parses text from URL if needed).
- **Other operations**: only support `text`; if a URL is provided, an error is thrown.

## Button Style Constants

| Constant                        | Purpose                                 | Value/Source                      |
|---------------------------------|-----------------------------------------|-----------------------------------|
| CraftifyButtonConstants.primaryColor   | Main button color                    | #ff807d                           |
| CraftifyButtonConstants.secondaryColor | Secondary button color              | #89e1c5                           |
| CraftifyButtonConstants.cornerRadius   | Corner radius                      | 20                                |
| CraftifyButtonConstants.horizontalPadding | Horizontal padding                  | 16                                |
| CraftifyButtonConstants.bottomPadding     | Bottom padding                          | 16                                |
| CraftifyButtonConstants.pressedScale      | Pressed scale                    | 0.97                              |

## Button Styles Overview

| Style      | Background Color           | Text Color | Font                | Corner Radius | Padding         | Pressed Scale | Usage Examples                |
|------------|---------------------------|------------|---------------------|---------------|----------------|---------------|------------------------------|
| Primary    | #ff807d (primaryColor)    | White      | .craftifyBody Bold  | 20            | 16 horiz/bottom | 0.97          | Save, Confirm, Main actions   |
| Secondary  | #89e1c5 (secondaryColor)  | Black      | .craftifyBody Bold  | 20            | 16 horiz/bottom | 0.97          | Cancel, Secondary actions     |
| Cancel     | #89e1c5 (secondaryColor)  | White      | .craftifyBody Bold  | 20            | 16 horiz/bottom | 0.97          | Cancel, Dismiss, Close        |
| Destructive| Transparent/Secondary     | Red        | .craftifyBody Bold  | 20            | 16 horiz/bottom | 0.97          | Delete, Remove, Danger action |

## DevOps-friendly Flow
- All dependencies between targets must be minimal and isolated.
- Use only embedAppExtensions for embedding extensions, not dependencies.
- Test dependencies must be in UnitTest targets only.
- This ensures clean production builds and prevents test libraries from leaking into production targets.

## References
- [Project Overview](project.md)
- [Architecture](architecture.md)
- [File Structure](file_structure.md)
- [Developer Manual](developer-manual.md)
- [User Manual](user-manual.md)

| Компонент | Назначение |
|-----------|------------|
| CraftifyPrimaryButtonStyle | Единый стиль для основных action-кнопок (шрифт, фон, скругление, высота) |
| CraftifySecondaryButtonStyle | Единый стиль для вторичных action-кнопок (например, Cancel) |
| CraftifyButtonBar | Контейнер для группы кнопок внизу формы, обеспечивает отступы и выравнивание |

**Изменения:**
- Весь стиль кнопок теперь задаётся через ButtonStyle.
- Удалены экспериментальные ViewModifier для текста кнопок.
- Кнопки на всех экранах MainApp используют только эти стили.

## Структура SupportedLanguages

- `SupportedLanguages.all` — массив всех поддерживаемых языков, каждый элемент — структура с кодом, самоназванием и английским названием.
- Используется для выбора языка в настройках и при переводе/суммаризации/объяснении.

## Технологии и зависимости
- Tuist — генерация и управление проектом (Project.swift, Workspace.swift)
- SwiftGen — генерация локализации и ресурсов
- SwiftLint, SwiftFormat — стиль и форматирование
- xcbeautify — форматирование вывода xcodebuild
- XcodeGen — [удалён, проект переведён на Tuist]

## Команды ./run
| Команда         | Описание                                      |
|----------------|-----------------------------------------------|
| ./run check    | Полный цикл: clean, generate, fmt, lint, test |
| ./run test id  | Запуск одного теста по идентификатору         |
| ./run sim      | Сборка MainApp для симулятора                 |
| ./run logs     | Просмотр логов MainApp                        |
| ./run generate | Генерация SwiftGen и Tuist                    |
| ./run clean    | Очистка артефактов сборки                     |
| ./run init     | Установка CLI-инструментов                    |
| ./run help     | Справка по командам                           |

## Переход на Tuist
- Project.swift и Workspace.swift описывают все targets, схемы, ресурсы
- project.yml, .xcodeproj, .xcworkspace и XcodeGen удалены
- Все сборки и тесты теперь только через tuist
+ Project.swift и Workspace.swift описывают все targets, схемы, ресурсы
+ project.yml, .xcodeproj, .xcworkspace и XcodeGen удалены (заменены на Tuist)
+ Все сборки и тесты теперь только через tuist

## AppSettingsManager
- Централизованный сервис для доступа к настройкам пользователя (язык и др.).
- Использует UserDefaults с поддержкой App Group для MainApp и ShareExtension.
- Все операции и ViewModel'и получают язык только через AppSettingsManager.shared.nativeLanguage.
- Все изменения настроек логируются через LogManagerShared.
- Реактивное обновление UI: выбранный язык хранится в @Published-свойстве ViewModel, применяется глобально только по кнопке Save.

## Технологический стек и зависимости
- Swift 5.9, SwiftUI, MVVM
- UserDefaults + App Group
- OSLogManagerShared для логирования
- SwiftGen, Tuist, XcodeGen
- Unit-тесты через XCTest

## Среда разработки и настройка
- Все зависимости и конфигурация через Project.swift, swiftgen.yml, .xcconfig
- Не требуется ручная настройка Xcode: всё воспроизводимо через CLI
- Для запуска: `./run init && ./run generate && ./run check`
