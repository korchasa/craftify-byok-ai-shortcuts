## Implementation and Technology Stack

### CLI Commands

| Command         | Description                                           |
|----------------|------------------------------------------------------|
| ./run test     | Run tests                                           |
| ./run deploy:simulator      | Build and run in iPhone 14 simulator (iOS 16)      |
| ./run clean    | Clean build artifacts                                |
| ./run logs     | View logs from Unified Log (system log, os_log, filtered by subsystem Internal, all levels, MainApp и ShareExtension) |
| ./run init     | Install all CLI dependencies via Homebrew           |
| add-operation-color | Позволяет выбрать цвет из палитры для операции. Цвет сохраняется в InventoryOperation и отображается в UI (главный экран, экран шаринга). Покрыто unit, UI и e2e тестами. |
| correct   | Исправление грамматики и орфографии, стиль всегда сохраняется максимально | {text} | - |

### Technology Stack
- Swift 5.7+
- SwiftUI
- XcodeGen
- SwiftPM (Common, LogManagerShared)
- New Relic
- SwiftGen (localization)
- GitHub Actions (CI/CD)

### Environment Setup
1. Clone the repository.
2. Install dependencies: run `./run init` (installs all CLI tools via Homebrew).
3. Generate the project: `xcodegen`.
4. Build and run: `./run deploy:simulator`.
5. For tests: `./run test`.

### CLI Tools

| Tool           | Version   | Purpose                          |
|----------------|-----------|----------------------------------|
| XcodeGen       | 2.42.0   | Generate Xcode project           |
| SwiftLint      | 0.59.1   | Swift style analyzer             |
| SwiftFormat    | 0.55.5   | Swift code formatter             |
| xcbeautify     | 2.28.0   | Beautiful output for xcodebuild  |
| swiftgen       | 6.6.3    | Localization code generation     |

All dependencies are installed via `./run init` using Homebrew. Mint and Mintfile are no longer used.

After completing step 2, all placeholder files and placeholder tests are removed. The project fully complies with linter requirements and is ready for Common implementation.

### DevOps and CI/CD

- GitHub Actions is used (`.github/workflows/ci.yml`).
- Caching is implemented to speed up builds:
  - DerivedData (`~/Library/Developer/Xcode/DerivedData`)
  - SwiftPM dependencies (`.build`, `.swiftpm`)
- Cache keys are built based on OS and control files (`Package.resolved`).
- Caching SwiftPM avoids re-downloading and rebuilding dependencies, speeding up the pipeline.
- Remove corrupted Package.resolved | rm -f **/Package.resolved | Removes all Package.resolved files before SPM caching and building, preventing errors due to corrupted files.

#### CI/CD: Non-functional Requirements Automation

- **Size report**: automatic check of ShareExtension size via `./run size-report` (fail if >20MB, artifact size-report.txt).
- **Comment scan**: automatic grep in src/ for TODO, FIXME, print, debugPrint (warning in CI).
- **Build-time metrics**: collection of build time and .appex size in metrics.json (artifact build-metrics).
- All checks are integrated into the workflow `.github/workflows/ci.yml`.

### Differences Between Local and CI/CD Builds

- **Locally**, all CLI tools are installed via `./run init` (Homebrew) and wrapper scripts `./run` (e.g., `./run test`, `./run deploy:simulator`) are used for all operations. This ensures consistency in tool versions and ease of execution.
- **In CI/CD (GitHub Actions)**, all utilities (swiftlint, swiftformat, xcodegen, xcodebuild, etc.) are installed and called directly, without Mint and without using `./run` scripts. This avoids the overhead of running Mint and speeds up execution.

**Example of local run:**
```
./run test
```

**Example in CI/CD:**
```
swiftlint
swiftformat . --lint --swiftversion 5.7
xcodegen
xcodebuild -project Craftify.xcodeproj -scheme Craftify -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 14,OS=16.4' build | xcbeautify
xcodebuild -project Craftify.xcodeproj -scheme Craftify -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 14,OS=16.4' test | xcbeautify
```

This difference allows speeding up CI/CD without losing reproducibility and version control of tools in local development.

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
- All methods are async/await (ready for integration with modern Swift code).
- Keychain access errors are handled and propagated (accessDenied, invalidKey, itemNotFound).
- Key masking: only the first 3 and last 4 characters are visible, the rest is replaced with ****.
- For tests, an in-memory stub (AuthManagerStub) is implemented, supporting the same methods.

**Example Usage:**
```swift
let authManager: AuthManaging = AuthManager()
try await authManager.setAPIKey("sk-...yourkey...")
let key = try await authManager.getAPIKey()
let masked = authManager.maskedAPIKey(key)
```

### API: LogManagerShared

**Purpose:**
- Centralized logging for the application and extension.
- In production, only OSLogManagerShared is used (Unified Logging, os_log, subsystem: Internal, only message + metadata).
- For tests — in-memory stub (LogManagerSharedInMemory).
- Key masking.

**Public Methods:**
| Method | Description |
|--------|-------------|
| `log(_ entry: LogEntry)` | Write log (system log, os_log) |
| `getLogs() -> [LogEntry]` | No-op in production, only for tests |
| `clearLogs()` | No-op in production, only for tests |
| `exportLogs() throws -> Data` | No-op in production, only for tests |

**Features:**
- In production: only system log (os_log, subsystem: Internal, only message + metadata), export and FIFO are not supported.
- For tests — in-memory implementation with FIFO and export.
- Key masking similar to AuthManager.

**Example Usage:**
```swift
let logger: LogManagerShared = OSLogManagerShared(category: ...)
logger.log(LogEntry(level: .info, module: "ShareExt", message: "Started", metadata: [:]))
```

### LogManagerShared: Implementation

- **Unified Logging Implementation (OSLogManagerShared):**
  - Stores logs in the system log (Unified Logging, os_log, subsystem: Internal, only message + metadata).
  - No FIFO or export, logs are available via Console.app or log stream.
  - Key masking is preserved in log messages.
  - File: `src/Common/Sources/OSLogManagerShared.swift`

- **In-memory Implementation (LogManagerSharedInMemory):**
  - Used for unit tests.
  - FIFO, masking, export similar to production.
  - File: `src/Common/Sources/LogManagerSharedInMemory.swift`

- **Protocol LogManagerShared:**
  - Describes a common API for logging, FIFO, export, masking.
  - File: `src/Common/Sources/LogManagerShared.swift`

- **Log Structure:**
  - LogEntry: level, module, message, metadata, timestamp.
  - File: `src/Common/Sources/LogEntry.swift`

### Testing AuthManager

| Test | Type | Description |
|------|------|-------------|
| `testSetAndGetAPIKey` | Unit | Check setting and getting API key via AuthManagerStub |
| `testDeleteAPIKey` | Unit | Check deleting API key via AuthManagerStub |
| `testSetShortAPIKeyThrows` | Unit | Check error when setting a short key |
| `testMaskedAPIKey` | Unit | Check key masking |
| `testMaskedAPIKeyShortOrNil` | Unit | Check masking of nil/short key |
| `testGetAPIKey_accessDenied_throws` | Unit | Check access error (accessDenied) via AuthManagerStub |
| `testGetAPIKey_itemNotFound_throws` | Unit | Check item not found error (itemNotFound) via AuthManagerStub |

### Testing Masking (maskKey)

| Test | Type | Description |
|------|------|-------------|
| `testMaskKey_NormalKey` | Unit | Masking a normal key (longer than min length, only last 4 characters visible) |
| `testMaskKey_ExactlyMinLength` | Unit | Masking a key exactly of minimum length (everything hidden) |
| `testMaskKey_ShortKey` | Unit | Masking a short key (everything hidden) |
| `testMaskKey_NilKey` | Unit | Masking nil (everything hidden) |

### Running Tests
- Unit and UI tests: `./run test`
- Coverage check: report is generated automatically in CI
- Mandatory requirement: all key user scenarios must be covered by end-to-end tests (E2E), including edge cases and negative scenarios.

### Share Extension

- Fully implemented Share Extension with support for all MVP requirements.
- Entitlements (App Groups, Keychain Access) configured for both targets.
- Text limit: 5000 characters, operation buttons blocked when exceeding the limit.
- Timeout handling: 15s per request, 30s total limit (Task.sleep + Task.cancel).
- Display toast/notification upon successful result copy.
- Integration with OSLogManagerShared: all actions and errors are logged, key masking.
- Coverage with unit, UI, and E2E tests (errors, timeouts, edge cases).
- In CI/CD, automatic size check for the extension is implemented (Archive + size report, fail if >20 MB).

### CI/CD Commands and Steps to Check Share Extension Size

| Step | Description |
|------|-------------|
| xcodegen | Generate Xcode project |
| xcodebuild build -scheme ShareExtension -configuration Release -sdk iphoneos | Build the extension in Release |
| du -sk build/Products/Release-iphoneos/ShareExtension.appex | Get the size of .appex |
| Fail if >20 MB | Build is interrupted if the size exceeds the limit |

### OpenAI Integration

**Architecture:**
- LLMAPIClient is used to send requests to the OpenAI API (gpt-4o-mini) via URLSession (ephemeral, 15s timeout).
- Retry with exponential backoff (1, 2, 5 seconds) is supported for network errors and 429.
- All requests and responses are logged via LogManagerShared.
- The OpenAI API key is always masked in logs (example: sk-****abcd).
- SLA: average response time ≤ 3 s (up to 1000 characters), ≤ 8 s (up to 5000 characters), total processing limit 30 s.
- All errors (401, 429, 500, parsing, timeout, cancel) are logged with details and metadata (operation, prompt, text length, maskedKey, status).
- Example log entry:
```json
{
  "level": "info",
  "module": "LLMAPIClient",
  "message": "Request to OpenAI sent",
  "metadata": {
    "operation": "translate",
    "prompt": "Translate: {text}",
    "length": "120",
    "maskedKey": "sk-****abcd"
  },
  "timestamp": "2024-06-10T12:34:56Z"
}
```
- For unit and integration tests, an in-memory logger (LogManagerSharedInMemory) is used.
- Load testing is performed using scripts and CI, SLA is checked automatically.
- All request parameters (model, temperature, max_tokens, promptTemplate) are fixed and logged.
- In case of error, the error type, maskedKey, response status, and OpenAI message are logged.

**Testing:**
- Unit test coverage: successful response, 401, 429, 500, cancel, retry, parsing error.
- Integration test: check request body, headers, response parsing, logging.
- Load test: ≥ 80% of requests meet the SLA.

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
