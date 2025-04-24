## Implementation and Technology Stack

### CLI Commands

| Command         | Description                                           |
|----------------|------------------------------------------------------|
| ./run test     | Run tests                                           |
| ./run dev      | Build and run in iPhone 14 simulator (iOS 16)      |
| ./run clean    | Clean build artifacts                                |
| ./run logs     | View logs                                           |

### Technology Stack
- Swift 5.7+
- SwiftUI
- XcodeGen
- SwiftPM (CraftifyShared, LogManagerShared)
- New Relic
- NDJSON file (FIFO, masking, atomic write, export, DispatchQueue) for logs
- SwiftGen (localization)
- GitHub Actions (CI/CD)

### Environment Setup
1. Clone the repository.
2. Install dependencies: Mint, SwiftGen, SwiftLint, SwiftFormat.
3. Generate the project: `xcodegen`.
4. Build and run: `./run dev`.
5. For tests: `./run test`.

### CLI Tools and Mint

| Tool           | Version   | Purpose                          |
|----------------|-----------|----------------------------------|
| XcodeGen       | 2.42.0   | Generate Xcode project           |
| SwiftLint      | 0.59.1   | Swift style analyzer             |
| SwiftFormat    | 0.55.5   | Swift code formatter             |
| xcbeautify     | 2.28.0   | Beautiful output for xcodebuild  |

Mint is used for managing versions of CLI tools. All dependencies are listed in the `Mintfile` at the root of the project.

After completing step 2, all placeholder files and placeholder tests are removed. The project fully complies with linter requirements and is ready for CraftifyShared implementation.

### DevOps and CI/CD

- GitHub Actions is used (`.github/workflows/ci.yml`).
- Caching is implemented to speed up builds:
  - Mint packages (`.mint`)
  - DerivedData (`~/Library/Developer/Xcode/DerivedData`)
  - SwiftPM dependencies (`.build`, `.swiftpm`)
- Cache keys are built based on OS and control files (`Mintfile`, `Package.resolved`).
- Caching SwiftPM avoids re-downloading and rebuilding dependencies, speeding up the pipeline.
- Remove corrupted Package.resolved | rm -f **/Package.resolved | Removes all Package.resolved files before SPM caching and building, preventing errors due to corrupted files.

### Differences Between Local and CI/CD Builds

- **Locally**, Mint and wrapper scripts `./run` (e.g., `./run test`, `./run dev`) are used for all operations. This ensures consistency in tool versions and ease of execution.
- **In CI/CD (GitHub Actions)**, to speed up the pipeline, all utilities (swiftlint, swiftformat, xcodegen, xcodebuild, etc.) are installed and called directly, without Mint and without using `./run` scripts. This avoids the overhead of running Mint and speeds up execution.

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
- FIFO log storage in NDJSON format (App Group container), supports in-memory stub for tests.
- Key masking, log export, atomic write.

**Public Methods:**
| Method | Description |
|--------|-------------|
| `log(_ entry: LogEntry)` | Write log (FIFO, NDJSON, atomic write) |
| `getLogs() -> [LogEntry]` | Retrieve all logs (FIFO) |
| `clearLogs()` | Clear all logs |
| `exportLogs() throws -> Data` | Export logs to JSON |

**Features:**
- NDJSON file in App Group (maximum 1000 entries, old ones automatically deleted).
- Key masking similar to AuthManager.
- For tests — in-memory implementation (LogManagerSharedInMemory).
- All operations are thread-safe (DispatchQueue).

**Example Usage:**
```swift
let logger: LogManagerShared = LogManagerSharedNDJSON(appGroupContainerURL: ...)
logger.log(LogEntry(level: .info, module: "ShareExt", message: "Started", metadata: [:]))
let logs = logger.getLogs()
let exported = try logger.exportLogs()
```

### LogManagerShared: Implementation

- **NDJSON Implementation (LogManagerSharedNDJSON):**
  - Stores logs in NDJSON file in App Group container.
  - FIFO: automatically deletes old entries when exceeding 1000.
  - All operations are thread-safe (DispatchQueue).
  - Key masking, log export, atomic write.
  - File: `src/CraftifyShared/Sources/LogManagerSharedNDJSON.swift`

- **In-memory Implementation (LogManagerSharedInMemory):**
  - Used for unit tests.
  - FIFO, masking, export similar to production.
  - File: `src/CraftifyShared/Sources/LogManagerSharedInMemory.swift`

- **Protocol LogManagerShared:**
  - Describes a common API for logging, FIFO, export, masking.
  - File: `src/CraftifyShared/Sources/LogManagerShared.swift`

- **Log Structure:**
  - LogEntry: level, module, message, metadata, timestamp.
  - File: `src/CraftifyShared/Sources/LogEntry.swift`

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
- Integration with LogManagerSharedNDJSON: all actions and errors are logged, key masking.
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

**Архитектура:**
- Используется LLMAPIClient для отправки запросов к OpenAI API (gpt-4o-mini) через URLSession (ephemeral, timeout 15 сек).
- Поддерживается retry с экспоненциальным backoff (1, 2, 5 сек) при сетевых ошибках и 429.
- Все запросы и ответы логируются через LogManagerShared (NDJSON, FIFO 1000 записей, atomic write, потокобезопасно).
- Ключ OpenAI API всегда маскируется в логах (пример: sk-****abcd).
- Логи доступны для экспорта пользователем (NDJSON/JSON).
- SLA: среднее время ответа ≤ 3 с (до 1000 символов), ≤ 8 с (до 5000 символов), общий лимит обработки 30 с.
- Все ошибки (401, 429, 500, parsing, timeout, cancel) логируются с деталями и метаданными (operation, prompt, длина текста, maskedKey, статус).
- Пример записи лога:
```json
{
  "level": "info",
  "module": "LLMAPIClient",
  "message": "Запрос к OpenAI отправлен",
  "metadata": {
    "operation": "translate",
    "prompt": "Translate: {text}",
    "length": "120",
    "maskedKey": "sk-****abcd"
  },
  "timestamp": "2024-06-10T12:34:56Z"
}
```
- Для unit- и интеграционных тестов используется in-memory логгер (LogManagerSharedInMemory).
- Нагрузочное тестирование проводится с помощью скриптов и CI, SLA проверяется автоматически.
- Все параметры запроса (model, temperature, max_tokens, promptTemplate) фиксированы и логируются.
- В случае ошибки логируется тип ошибки, maskedKey, статус ответа, сообщение OpenAI.

**Тестирование:**
- Покрытие unit-тестами: успешный ответ, 401, 429, 500, cancel, retry, parsing error.
- Интеграционный тест: проверка тела запроса, заголовков, парсинга ответа, логирования.
- Нагрузочный тест: ≥ 80% запросов укладываются в SLA.

## Особенности реализации таймаута
- Таймаут обработки текста реализован только в ShareExtensionViewModel (по умолчанию 30 секунд, можно переопределять в тестах через processingTimeoutSeconds).
- В ShareExtensionManager таймаут не реализован, только бизнес-логика обработки и ошибок.
- В unit-тестах ViewModel таймаут выставляется через processingTimeoutSeconds.
- В E2E тестах ShareExtensionManager проверяются только ошибки и успехи обработки, но не таймаут.