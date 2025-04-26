## Architecture Craftify

### General Scheme
- The main application (SwiftUI) and Share Extension use a common module Common (SwiftPM).
- Interaction between modules through App Group (UserDefaults) and Keychain Sharing.
- Logging through LogManagerShared (SPM), storing logs in the App Group container (NDJSON file, FIFO, masking, export, atomic write, DispatchQueue).

### Key Patterns
- MVVM + SwiftUI for UI and business logic.
- Dependency Injection for managers.
- FIFO for logs (limit of 1000 entries).

### Logging and Analytics

#### Log Architecture
- Все логи пишутся через системный лог (Unified Logging, os_log) через OSLogManagerShared. Экспорт логов не поддерживается, просмотр через Console.app или log stream.
- LogManagerShared поддерживает уровни: debug, info, warning, error.
- Ключи API всегда маскируются (видны только первые и последние 4 символа).
- Краш-репортинг реализован через New Relic SDK, интегрирован только в основное приложение (не в Share Extension).
- New Relic App Token хранится в Info.plist и подставляется в рантайме.
- В Share Extension не используются сторонние SDK для аналитики или crash reporting (минимальный размер, соответствие App Store).

#### Log Export and Retention Policy
- Экспорт логов не поддерживается (ограничение системного лога). Просмотр логов — через Console.app или log stream.
- Краш-отчёты отправляются только из основного приложения через New Relic SDK.

#### Consequences
- Логи доступны для диагностики только через системные средства.
- Краш-аналитика доступна только для основного приложения через New Relic.
- Share Extension остаётся лёгким и соответствует требованиям приватности.
- Политика маскирования логов реализована на уровне кода.

### Component Interaction
- ShareExtensionManager reads inventory and API key, calls ProcessingManager.
- ProcessingManager forms a request, calls LLMAPIClient.
- LLMAPIClient sends HTTP POST to OpenAI, parses the response through ResponseParser.
- ClipboardManager copies the result to UIPasteboard.
- All actions are logged through LogManagerShared.

### Error Handling
- All errors (Keychain, network, parsing, clipboard) are handled with an Alert display.
- Retries on network errors (exponential backoff).
- Masking of the API key in logs.
- In case of key access errors — suggestion to open Settings.

### Testing
- Unit tests for all managers.
- UI/E2E tests for main scenarios (mandatory requirement: all key user scenarios must be covered by end-to-end tests, including edge cases and negative scenarios).
- Coverage ≥ 80% for key modules.

### Results of Share Extension Implementation
- Architectural solutions (DI, logging, error handling, testability) implemented in full compliance with documentation.
- All components and interactions correspond to the description in this architecture.

### Share Extension: Final Architecture

- All managers are injected through DI, including OSLogManagerShared (Unified Logging, system log).
- Logging of all actions and errors, key masking, FIFO, NDJSON export.
- Text limit: 5000 characters, blocking on UI and in the manager.
- Timeouts: 15 seconds per request, 30 seconds total limit (Task.sleep + Task.cancel).
- Error handling: all scenarios covered (no text, limit, no consent, invalid key, network, parsing, buffer, cancellation).
- Coverage of unit, UI, E2E tests (≥80%).
- In CI/CD, automatic size check of the extension is implemented (Archive + size report, fail if >20 MB).

#### Updated Interaction Diagram

```mermaid
graph TD
  ShareExtension[Share Extension] -->|UserDefaults| AppGroup[UserDefaults (App Group)]
  ShareExtension --> ProcessingManager[Processing Manager]
  ProcessingManager --> LLMAPIClient[LLM API Client]
  LLMAPIClient --> UIPasteboard[UIPasteboard]
  subgraph Shared
    LogManagerShared[Log Manager Shared]
  end
  ShareExtension & ProcessingManager & LLMAPIClient & UIPasteboard -.-> LogManagerShared
```

+### Targets and Dependencies
+
+```mermaid
+graph LR
+  subgraph "Modules"
+    Common[Common (SPM Framework)]
+    MainApp[MainApp (iOS App)]
+    ShareExt[ShareExtension (App Extension)]
+  end
+
+  Common --> MainApp
+  Common --> ShareExt
+  MainApp -->|embedAppExtensions| ShareExt
+  subgraph "App Group / Keychain"
+    AG[App Group: group.dev.korchasa.Craftify]
+    KC[Keychain Access Group: group.dev.korchasa.Craftify]
+  end
+
+  MainApp --- AG
+  ShareExt --- AG
+  MainApp --- KC
+  ShareExt --- KC
+```
+
+### Flow of `./run deploy:simulator`
+
+```mermaid
+flowchart TB
+  A[./run deploy:simulator] --> B[SwiftGen]
+  B --> C[XcodeGen]
+  C --> D[Build MainApp for simulator]
+  D --> E[Boot Simulator (if not running)]
+  E --> F[simctl install MainApp.app]
+  F --> G[Launch MainApp in Simulator]
+```

## Механизм таймаута обработки текста
- Таймаут обработки реализован только на уровне ShareExtensionViewModel (по умолчанию 30 секунд, можно переопределять в тестах).
- ShareExtensionManager не реализует таймаут, только бизнес-логику обработки и ошибок.
- В unit-тестах ViewModel таймаут выставляется через processingTimeoutSeconds.
- В E2E тестах ShareExtensionManager проверяются только ошибки и успехи обработки, но не таймаут.