# Craftify Implementation & Stack

---

## Stack
- Swift 5.7+, SwiftUI, SwiftPM, SwiftGen, GitHub Actions, SwiftSoup, URLSession
- TDD: unit tests for all error branches
- SupportedLanguages: ISO-639-1 + artificial (Klingon, Sindarin, etc.)
- LLM message templates: `makeMessages()` always uses `AppSettingsManager.shared.nativeLanguageEnglishName` to localise system/user messages
- Periphery: dead code analyzer in lint

## Setup
1. Clone repo
2. `./run init` (installs CLI tools)
3. `./run generate` (tuist, swiftgen)
4. `./run sim`
5. Tests: `./run check`

## CLI Tools
| Tool        | Version | Purpose                |
|-------------|---------|------------------------|
| Tuist       | latest  | Xcode project gen      |
| SwiftLint   | 0.59.1  | Style analyzer         |
| SwiftFormat | 0.55.5  | Code formatter         |
| xcbeautify  | 2.28.0  | xcodebuild output      |
| swiftgen    | 6.6.3   | L10n code gen          |

## DevOps/CI
- GitHub Actions: `.github/workflows/ci.yml`
- Caching: DerivedData, SwiftPM deps
- CI checks: size report, comment scan, build metrics
- ShareExt size auto-check (fail if >20MB)

## API: AuthManager
| Method                        | Description                        |
|-------------------------------|------------------------------------|
| getAPIKey() async throws       | Get API key                        |
| setAPIKey(_ key) async throws  | Save API key (validate length)     |
| deleteAPIKey() async throws    | Delete API key                     |
| maskedAPIKey(_ key)           | Mask for logs (sk-****abcd)        |
- All async/await, errors handled, masking: 3+4 chars (works for any LLM provider)

## API: LogManagerShared
| Method         | Description                |
|----------------|---------------------------|
| log(_ entry)   | Write log (os_log)        |
| getLogs()      | No-op prod, for tests     |
| clearLogs()    | No-op prod, for tests     |
| exportLogs()   | No-op prod, for tests     |
- Prod: only system log, no export/FIFO
- Tests: in-memory FIFO, export
- Key masking as in AuthManager

## Testing
- Unit/UI: `./run check`
- Coverage auto-checked in CI
- All error branches tested

## Timeout
- Only in ShareExtensionViewModel (30s, override in tests)
- ShareExtensionManager: only logic

## Logs
- `./run logs`: outputs os_log (last day, subsystem dev.korchasa.Craftify, JSON)

## Default Operations Inventory

At first launch `InventoryManager.fillWithDefaultOperationsIfNeeded()` seeds the user's inventory with a ready-to-use set of seven operations (six when the device language is English). They are ordered by the expected frequency of use:

| # | Kind | Params | Purpose |
|---|------|--------|---------|
|1|translate|targetLanguage = *deviceLang*|Quickly convert copied text into the UI language (device localisation).|
|2|translate|targetLanguage = `en` (*skipped if* `deviceLang == "en"`)|Widely used lingua-franca translation.|
|3|simplify|—|Remove jargon and formal language, making text short & easy.|
|4|correct|—|Fix grammar/spelling mistakes.|
|5|summarize|length = "9-10 sentences"|Produce medium-length digest of large text/URL.|
|6|explain|—|Explain complex text or code in simple words.|
|7|translate|targetLanguage = `sjn` (Sindarin)|Fun/novelty translation for sharing.|

No duplicates are added—helper `appendTranslate()` skips already inserted targetLanguage codes.

---

## Operation Color
- InventoryOperation: colorHex
- InventoryManager: colorHex serialization
- Add/EditOperationView: color palette UI
- HomeView/ShareExtView: color indicator
- Tests: InventoryOperation, InventoryManager, Add/EditOperationView

## Onboarding
- AppState: consent flag (@StateObject)
- HowToUseView shows the full Privacy Policy and an **Accept & Continue** button.
- After acceptance, consent flag is set and stored via ConsentManager (UserDefaults App Group).

## Schemas
- MainApp, ShareExtension, ShareExtensionSizeReport

## ShareExt UI
```mermaid
graph TD
  ShareExtensionView
  CloseButton[Close (fixed bottom)]
  ScrollView[Content]
  Overlay[Progress, Toast]
  ShareExtensionView --> ScrollView
  ShareExtensionView --> CloseButton
  ShareExtensionView --> Overlay
  ScrollView -->|contains| Title
  ScrollView -->|contains| Result
  ScrollView -->|contains| OperationsList
```
- Close always at bottom via .safeAreaInset
- All content in ScrollView
- Overlays: ZStack
- All tested

## URL Sharing
- ShareExt: text (UTType.plainText), URL (UTType.url)
- If both: text priority
- 5000 char limit
- UI: only ops with URL support shown
- Summarize: text or URL

## ShareExtensionViewModel
- Async data load (URL/text)
- Logs: all stages, first 100 chars
- Modular, SRP
- Timeout: built-in
- Ops filtered for URL/text
- All tested

## Input Handling
- All ops: async `resolveInput(input)` before LLM
- Summarize: text+url; others: text only (URL → error)

## Button Constants
| Constant                        | Purpose             | Value         |
|---------------------------------|---------------------|--------------|
| primaryColor                    | Main btn color      | #ff807d      |
| secondaryColor                  | Secondary btn color | #89e1c5      |
| cornerRadius                    | Corner radius       | 20           |
| horizontalPadding               | Horizontal padding  | 16           |
| bottomPadding                   | Bottom padding      | 16           |
| pressedScale                    | Pressed scale       | 0.97         |

## Button Styles
| Style                       | Bg Color  | Text | Font             | Radius | Padding | Scale | Usage                                |
|-----------------------------|-----------|------|------------------|--------|---------|-------|--------------------------------------|
| CraftifyPrimaryButtonStyle  | #ff807d   | W    | .craftifyBody B  | 20     | 16      | 0.97  | Save, Confirm, primary actions       |
| GraySecondaryButtonStyle    | #ececec   | B    | .craftifyBody B  | 20     | 16      | 0.97  | Cancel/secondary actions in forms    |
| SettingsPrimaryButtonStyle  | #89e1c5   | W    | .craftifyBody B  | 20     | 16      | 0.97  | Primary action on Settings screen    |
| Destructive (Secondary+Red) | Clear     | R    | .craftifyBody B  | 20     | 16      | 0.97  | Delete, irreversible actions         |

## DevOps
- Minimal, isolated target deps
- Only embedAppExtensions for extensions
- Test deps only in UnitTest targets

## References
- [Project Overview](project.md)
- [Architecture](architecture.md)
- [File Structure](file_structure.md)
- [Developer Manual](developer-manual.md)
- [User Manual](user-manual.md)

## Components
| Component                     | Purpose                                            |
|-------------------------------|----------------------------------------------------|
| CraftifyPrimaryButtonStyle    | Main action button style                            |
| GraySecondaryButtonStyle      | Gray secondary style used for cancel buttons        |
| SettingsPrimaryButtonStyle    | Primary action style specifically for Settings view |
| CraftifyButtonBar             | Button group container (bottom, spacing)            |
| MarkdownLLMView              | SwiftUI view that renders Markdown responses from LLM |
| URLInputResolver             | Shared helper that converts a URL into plain text via `TextFetching` |

## SupportedLanguages
- `SupportedLanguages.all`: all supported (ISO-639-1 + artificial)
- Used for language selection in settings, ops

## Stack
- Tuist: project gen
- SwiftGen: l10n/resources
- SwiftLint, SwiftFormat: style
- xcbeautify: xcodebuild output

## AppSettingsManager
- Централизованный сервис для доступа к настройкам пользователя (язык и др.).
- Использует UserDefaults с поддержкой App Group для MainApp и ShareExtension.
- Все операции и ViewModel'и получают язык только через AppSettingsManager.shared.nativeLanguage.
- Все изменения настроек логируются через LogManagerShared.
- Реактивное обновление UI: выбранный язык хранится в @Published-свойстве ViewModel, применяется глобально только по кнопке Save.

## LLM Provider & Factory

- `LLMProvider` (enum) lists supported providers: `openAI`, `claude`.
  Stored in `AppSettingsManager.llmProvider` and selectable in **SettingsView** via a `Picker`.
- `LLMClienting` protocol defines a single `send(messages: [LLMMessage], apiKey: String) async` method that accepts a provider-agnostic chat history.
- `OpenAIAPIClient` and `ClaudeAPIClient` conform to `LLMClienting` and wrap the respective REST APIs (retry logic, time-outs, JSON parsing).
- `LLMClientFactory` instantiates the proper client based on the selected provider.
  By default `ProcessingManager` asks the factory every time to stay in sync with user choice.

This refactor removes the hard dependency on OpenAI and enables quick addition of new vendors.

## Технологический стек и зависимости
- Swift 5.9, SwiftUI, MVVM
- UserDefaults + App Group
- OSLogManagerShared для логирования
- SwiftGen, Tuist
- Unit-тесты через XCTest

## Среда разработки и настройка
- Все зависимости и конфигурация через Project.swift, swiftgen.yml, .xcconfig
- Не требуется ручная настройка Xcode: всё воспроизводимо через CLI
- Для запуска: `./run init && ./run generate && ./run check`
