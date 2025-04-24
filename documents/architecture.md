## Architecture Craftify

### General Scheme
- The main application (SwiftUI) and Share Extension use a common module CraftifyShared (SwiftPM).
- Interaction between modules through App Group (UserDefaults) and Keychain Sharing.
- Logging through LogManagerShared (SPM), storing logs in the App Group container (NDJSON file, FIFO, masking, export, atomic write, DispatchQueue).

### Key Patterns
- MVVM + SwiftUI for UI and business logic.
- Dependency Injection for managers.
- FIFO for logs (limit of 1000 entries).

### Logging and Analytics

#### Log Architecture
- Все логи пишутся в формате NDJSON в файл в контейнере App Group через LogManagerShared.
- LogManagerShared поддерживает уровни: debug, info, warning, error.
- Лог-файл ограничен 1000 записями (FIFO), при превышении лимита старые записи удаляются автоматически.
- Все операции записи потокобезопасны (DispatchQueue), запись атомарная.
- Ключи API всегда маскируются (видны только первые и последние 4 символа).
- Экспорт логов доступен через SettingsView (share sheet), файл в формате JSON.
- Логи доступны только внутри контейнера App Group и не передаются третьим лицам.
- Краш-репортинг реализован через New Relic SDK, интегрирован только в основное приложение (не в Share Extension).
- New Relic App Token хранится в Info.plist и подставляется в рантайме.
- В Share Extension не используются сторонние SDK для аналитики или crash reporting (минимальный размер, соответствие App Store).

#### Log Export and Retention Policy
- Пользователь может экспортировать логи через SettingsView.
- Логи содержат максимум 1000 последних записей (FIFO), все ключи API маскированы.
- Логи доступны только внутри контейнера App Group.
- Краш-отчёты отправляются только из основного приложения через New Relic SDK.

#### Consequences
- Логи всегда доступны для экспорта и диагностики.
- Краш-аналитика доступна только для основного приложения через New Relic.
- Share Extension остаётся лёгким и соответствует требованиям приватности.
- Политика хранения и маскирования логов реализована на уровне кода.

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

- All managers are injected through DI, including LogManagerSharedNDJSON (App Group).
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

## Механизм таймаута обработки текста
- Таймаут обработки реализован только на уровне ShareExtensionViewModel (по умолчанию 30 секунд, можно переопределять в тестах).
- ShareExtensionManager не реализует таймаут, только бизнес-логику обработки и ошибок.
- В unit-тестах ViewModel таймаут выставляется через processingTimeoutSeconds.
- В E2E тестах ShareExtensionManager проверяются только ошибки и успехи обработки, но не таймаут.