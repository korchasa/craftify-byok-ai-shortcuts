## Implementation and Technology Stack

### CLI Commands

| Command         | Description                                           |
|----------------|------------------------------------------------------|
| ./run check     | Run tests, lint, format, size-report, comment-scan, etc. |
| ./run deploy:simulator      | Build and run in iPhone 14 simulator (iOS 16)      |
| ./run clean    | Clean build artifacts                                |
| ./run logs     | View logs from Unified Log (system log, os_log, filtered by subsystem Internal, all levels, MainApp и ShareExtension) |
| ./run init     | Install all CLI dependencies via Homebrew           |
| ./run generate | Run SwiftGen and XcodeGen (localization, project)   |
| ./run size-report | Check ShareExtension size (fail if >20MB)         |
| add-operation-color | Позволяет выбрать цвет из палитры для операции. Цвет сохраняется в InventoryOperation и отображается в UI (главный экран, экран шаринга). Покрыто unit, UI и e2e тестами. |
| correct   | Исправление грамматики и орфографии, стиль всегда сохраняется максимально | {text} | - |
| summarize-url | Summarize text from a web page by URL or plain text | SummarizeOperation, SwiftSoupTextFetcher | Accepts either direct text or URL, downloads HTML if needed, extracts <body> text, summarizes |
| resolveInput | Асинхронно получает текст для LLM: для Summarize поддерживает url (загрузка и парсинг текста), для остальных — только text, url вызывает ошибку | OperationType | input: OperationInput, output: String (async) |

### Technology Stack
- Swift 5.7+
- SwiftUI
- XcodeGen
- SwiftPM (Common, LogManagerShared)
- New Relic
- SwiftGen (localization)
- GitHub Actions (CI/CD)
- Поддержка resultMode (clipboard/display) для операций
- SwiftSoup (HTML parsing)
- URLSession (networking)
- TDD (unit tests for all error branches)

### Environment Setup
1. Clone the repository.
2. Install dependencies: run `./run init` (installs all CLI tools via Homebrew).
3. Generate the project: `xcodegen`.
4. Build and run: `./run deploy:simulator`.
5. For tests: `./run check`.

### CLI Tools

| Tool           | Version   | Purpose                          |
|----------------|-----------|----------------------------------|
| XcodeGen       | 2.42.0   | Generate Xcode project           |
| SwiftLint      | 0.59.1   | Swift style analyzer             |
| SwiftFormat    | 0.55.5   | Swift code formatter             |
| xcbeautify     | 2.28.0   | Beautiful output for xcodebuild  |
| swiftgen       | 6.6.3    | Localization code generation     |

All dependencies are installed via `./run init` using Homebrew. Mint и Mintfile больше не используются.

### DevOps and CI/CD

- GitHub Actions is used (`.github/workflows/ci.yml`).
- Кэширование ускоряет сборки:
  - DerivedData (`~/Library/Developer/Xcode/DerivedData`)
  - SwiftPM dependencies (`.build`, `.swiftpm`)
- Ключи кэша строятся по OS и control-файлам (`Package.resolved`).
- Кэширование SwiftPM ускоряет pipeline.
- Проверка размера ShareExtension (`./run size-report`, fail если >20MB).
- Проверка комментариев (TODO, FIXME, print, debugPrint).
- Все проверки интегрированы в workflow.

#### CI/CD: Non-functional Requirements Automation

- **Size report**: автоматическая проверка размера ShareExtension.
- **Comment scan**: автоматический grep в src/ на TODO, FIXME, print, debugPrint.
- **Build-time metrics**: сбор метрик времени сборки и размера .appex.
- Все проверки интегрированы в `.github/workflows/ci.yml`.

### Differences Between Local and CI/CD Builds

- **Локально**: все CLI-инструменты устанавливаются через `./run init` (Homebrew), используются wrapper-скрипты `./run` для всех операций.
- **В CI/CD**: все утилиты (swiftlint, swiftformat, xcodegen, xcodebuild и др.) устанавливаются и вызываются напрямую, без Mint и без использования `./run`.

### API: AuthManager

**Purpose:**
- Secure storage and retrieval of OpenAI API key via Keychain with Keychain Sharing support (App Group).
- Masking the key for logging.
- Used in all modules via the `AuthManaging` protocol (DI-friendly, supports stub for tests).

**Public Methods:**
| Method | Description |
|--------|-------------|
| `getAPIKey() async throws -> String?` | Retrieve API key (or nil if not found) |
| `setAPIKey(_ key: String) async throws` | Save API key (length validated) |
| `deleteAPIKey() async throws` | Delete API key |
| `maskedAPIKey(_ key: String?) -> String` | Masks the key for logging (example: sk-****abcd) |

**Features:**
- Все методы async/await.
- Ошибки доступа к Keychain обрабатываются и пробрасываются.
- Маскирование ключа: только первые 3 и последние 4 символа видны.
- Для тестов — in-memory stub (AuthManagerStub).

### API: LogManagerShared

**Purpose:**
- Централизованное логирование для приложения и расширения.
- В production — только OSLogManagerShared (Unified Logging, os_log, subsystem: Internal, только message + metadata).
- Для тестов — in-memory stub (LogManagerSharedInMemory).
- Маскирование ключей.

**Public Methods:**
| Method | Description |
|--------|-------------|
| `log(_ entry: LogEntry)` | Write log (system log, os_log) |
| `getLogs() -> [LogEntry]` | No-op in production, only for tests |
| `clearLogs()` | No-op in production, only for tests |
| `exportLogs() throws -> Data` | No-op in production, only for tests |

**Features:**
- В production: только system log, экспорт и FIFO не поддерживаются.
- Для тестов — in-memory реализация с FIFO и экспортом.
- Маскирование ключей аналогично AuthManager.

### Testing AuthManager и LogManager
- Unit-тесты для всех методов, включая маскирование, ошибки доступа, удаление ключа.
- Покрытие ≥ 80%.

### Share Extension и resultMode
- Для всех операций теперь поддерживается признак обработки результата (resultMode):
  - `.clipboard` — результат копируется в буфер обмена (по умолчанию для всех операций).
  - `.display` — результат отображается во всплывающем окне (используется для Explain).
- UI (ShareExtensionView) корректно отображает результат Explain с прокруткой, для остальных операций — тост о копировании.
- Покрыто unit, UI и e2e тестами (режимы clipboard/display, Explain, ошибки, edge cases).

### Running Tests
- Unit и UI тесты: `./run check`
- Проверка покрытия: автоматически в CI
- Все ключевые сценарии покрыты e2e-тестами, включая Explain (display) и clipboard-операции.

### CI/CD: Проверка размера и покрытия
- В CI/CD автоматически проверяется размер ShareExtension и покрытие тестами (≥80%).

### Developer Notes
- Не редактируйте Info.plist и entitlements вручную. Все изменения — только через project.yml и XcodeGen.
- Все менеджеры внедряются через протоколы для тестируемости.
- Для Explain результат отображается во всплывающем окне, для остальных — копируется в буфер.

## Timeout Implementation Details
- Text processing timeout is implemented only in ShareExtensionViewModel (default 30 seconds, can be overridden in tests via processingTimeoutSeconds).
- ShareExtensionManager does not implement a timeout, only business logic for processing and errors.
- In unit tests, the ViewModel timeout is set via processingTimeoutSeconds.
- In E2E tests, ShareExtensionManager only checks for processing errors and successes, not timeout.

| Requirement | Description |
| --- | --- |
| Info.plist and entitlements configuration | Do not edit Info.plist and entitlements directly. All changes must be made only through project.yml, which is processed by XcodeGen. |

### Receiving Logs (Unified Log)
- To view the logs, use the command:
  ```sh
  ./run logs
  ```
- The command outputs logs from the unified log (os_log) for the last day, filtering by the subsystem "dev.korchasa.Craftify" in JSON format.
- To change the period, use the log show options, for example:
  ```sh
  log show --predicate 'subsystem == "dev.korchasa.Craftify"' --style json --last 2h
  ```

| `ci` (GitHub Actions) | Автоматический запуск lint, форматирования, тестов, сборки и деплоя через актуальные команды `./run`. Все шаги workflow используют только существующие команды из скрипта. Ручная работа в Xcode не требуется. |

### Operation Color Implementation
- InventoryOperation: добавлено свойство colorHex (hex-код цвета).
- InventoryManager: поддержка сериализации/десериализации colorHex.
- AddOperationView/EditOperationView: UI-палитра для выбора цвета.
- HomeView/ShareExtensionView: отображение цвета операции (индикатор).
- Покрытие: unit-тесты (InventoryOperation, InventoryManager), UI-тесты (Add/EditOperationView), e2e-тесты (ShareExtensionView).

- В моделях и UI убран параметр stylePreservationLevel для correct-операции, всегда используется максимальный стиль.

### Onboarding Flow (Welcome Screen)
- AppState (ObservableObject) с Published-флагом согласия пользователя.
- Используется через @StateObject в CraftifyApp.
- HowToUseView принимает onConsent callback, который вызывается после согласия.
- После согласия — автоматический переход на HomeView.
- Согласие хранится через ConsentManager (UserDefaults App Group).
- Покрыто e2e-тестом на полный flow.

## Project Schemas

- MainApp
- MainAppUnitTests
- MainAppE2ETests
- ShareExtension
- ShareExtensionUnitTests
- ShareExtensionE2ETests
- CommonUnitTests
- CommonE2ETests
- ShareExtensionSizeReport

- ### Описание операций и промптов
-
-#### CorrectOperation
- ...
-#### ExplainOperation
- ...
-#### SimplifyOperation
- ...
-#### TranslateOperation
- ...

**Подробные описания схем, операций и промптов см. в architecture.md, user-manual.md, developer-manual.md.**

## ShareExtension: UI окна шаринга

| Компонент         | Описание |
|-------------------|----------|
| Кнопка закрытия   | Всегда закреплена внизу экрана через `.safeAreaInset`, с фиксированным отступом. |
| Контент           | Весь остальной контент (заголовок, результат, список операций) находится в едином ScrollView. |
| Прокрутка         | Контент всегда прокручивается, если не помещается на экране. |
| Перекрытие        | Контент не перекрывается кнопкой, так как у ScrollView добавлен нижний padding. |
| Оверлеи           | Индикатор процесса и тост отображаются поверх основного содержимого. |
| Стиль             | Используется современный SwiftUI-подход для закрепления элементов интерфейса. |
| Тесты             | Все изменения покрыты unit- и e2e-тестами. |
| Качество          | Линтер и форматтер проходят без ошибок. |

### URL Sharing Support
- Share Extension теперь поддерживает шаринг не только текста (UTType.plainText), но и URL (UTType.url).
- Если пользователь отправляет ссылку через меню "Поделиться", она автоматически преобразуется в строку и обрабатывается как обычный текст.
- Если в одном шаринге есть и текст, и URL — приоритет у текста.
- Лимит длины (5000 символов) применяется и к URL.
- Покрыто unit- и e2e-тестами.

## Technology stack and dependencies (update)
- Swift
- SwiftSoup (HTML parsing)
- URLSession (networking)
- TDD (unit tests for all error branches)

## Development environment and setup (update)
- Add SwiftSoup via SPM in project.yml
- All code for text fetching is in src/Common/Sources/TextFetcher
- No manual Xcode configuration required

- `src/Common/Sources/Models/OperationInput.swift` — добавлено поле `url: String?` и `text: String?` для передачи URL или текста в операции

## Input Handling for Operations

All operations now implement an async method `resolveInput(input: OperationInput) -> String`, which is always called before sending data to LLM:
- **SummarizeOperation**: supports both `text` and `url` (fetches and parses text from URL if needed).
- **Other operations**: only support `text`; if a URL is provided, an error is thrown.

The ViewModel always calls `resolveInput` and passes the result to the LLM, ensuring URLs are never sent directly.

### Ограничения по входным данным операций

| Операция              | Поддержка text | Поддержка url |
|----------------------|:--------------:|:-------------:|
| SummarizeOperation   |      Да        |      Да       |
| TranslateOperation   |      Да        |      Нет      |
| SimplifyOperation    |      Да        |      Нет      |
| CorrectOperation     |      Да        |      Нет      |
| ExplainOperation     |      Да        |      Нет      |

- Для SummarizeOperation: resolveInput асинхронно загружает и парсит текст по url (через TextFetcher), либо возвращает text.
- Для остальных операций: resolveInput принимает только text, url вызывает ошибку (ошибка с доменом <OperationName>Operation).
- ViewModel всегда вызывает resolveInput перед отправкой текста в LLM.
- Покрыто unit-тестами для всех операций (text и url).

## Button Style Constants

| Constant                        | Purpose                                 | Value/Source                      |
|---------------------------------|-----------------------------------------|-----------------------------------|
| CraftifyButtonConstants.primaryColor   | Основной цвет кнопки                    | #ff807d                           |
| CraftifyButtonConstants.secondaryColor | Второстепенный цвет кнопки              | #89e1c5                           |
| CraftifyButtonConstants.cornerRadius   | Радиус скругления                      | 20                                |
| CraftifyButtonConstants.horizontalPadding | Горизонтальный отступ                  | 16                                |
| CraftifyButtonConstants.bottomPadding     | Нижний отступ                          | 16                                |
| CraftifyButtonConstants.pressedScale      | Масштаб при нажатии                    | 0.97                              |

**Использование:**
- Все основные кнопки во всех экранах используют эти константы через `.buttonStyle(CraftifyPrimaryButtonStyle())` и `.buttonStyle(CraftifySecondaryButtonStyle())`.
- Отступы и радиус применяются через `.padding(.horizontal, ...)`, `.padding(.bottom, ...)`, `.cornerRadius(...)`.

## Button Styles Overview

| Style      | Background Color           | Text Color | Font                | Corner Radius | Padding         | Pressed Scale | Usage Examples                |
|------------|---------------------------|------------|---------------------|---------------|----------------|---------------|------------------------------|
| Primary    | #ff807d (primaryColor)    | White      | .craftifyBody Bold  | 20            | 16 horiz/bottom | 0.97          | Save, Confirm, Main actions   |
| Secondary  | #89e1c5 (secondaryColor)  | Black      | .craftifyBody Bold  | 20            | 16 horiz/bottom | 0.97          | Cancel, Secondary actions     |
| Cancel     | #89e1c5 (secondaryColor)  | White      | .craftifyBody Bold  | 20            | 16 horiz/bottom | 0.97          | Cancel, Dismiss, Close        |
| Destructive| Transparent/Secondary     | Red        | .craftifyBody Bold  | 20            | 16 horiz/bottom | 0.97          | Delete, Remove, Danger action |

**Notes:**
- Все параметры берутся из CraftifyButtonConstants и Font+Craftify.
- Для Destructive-кнопок используйте `.foregroundColor(.red)` или `.tint(.red)`.
- Не создавайте локальных ButtonStyle — только централизованные.
