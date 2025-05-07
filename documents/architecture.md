# Craftify Architecture
---

## System Overview
- MainApp (SwiftUI) and Share Extension both use the shared Common module (SwiftPM).
- Modules interact via App Group (UserDefaults) and Keychain Sharing.
- Logging is centralized via LogManagerShared (SPM), using os_log.
- All operations support a result processing mode (`resultMode`):
  - `.clipboard`: result is copied to the clipboard (default)
  - `.display`: result is shown in a popup window (used for Explain)

## System Layers
- **UI Layer**: SwiftUI Views и ViewModel'и. Все ViewModel'и получают настройки только через AppSettingsManager, не хранят копии языка в OperationInput.
- **Settings Layer**: AppSettingsManager — централизованный сервис для доступа к настройкам пользователя (язык, и др.), реализует хранение через UserDefaults/App Group, поддерживает логирование изменений.
- **Operations Layer**: Все операции (Summarize, Explain и др.) получают язык только через AppSettingsManager.shared.nativeLanguage при каждом вызове, не сериализуют язык в параметры.

## Key Design Patterns
- MVVM + SwiftUI for UI and business logic
- Dependency Injection for managers
- FIFO for logs (limit 1000 entries)
- **Singleton**: AppSettingsManager.shared используется во всех слоях для доступа к настройкам.
- **Reactive UI**: Выбранный язык в настройках хранится в @Published-свойстве ViewModel, UI обновляется мгновенно, но сохранение происходит только по кнопке Save.
- **Dependency Injection**: Операции и сервисы получают зависимости через инициализаторы (например, logManager).

## Logging and Analytics
- All logs are written via Unified Logging (os_log, subsystem: Internal, message + metadata only) through OSLogManagerShared.
- LogManagerShared supports levels: debug, info, warning, error. In production, only message + metadata are logged.
- API keys are always masked (only the first and last 4 characters are visible).
- No third-party SDKs for analytics or crash reporting are used in the Share Extension (minimal size, App Store compliance).
- Log export is not supported (system log limitation). Viewing is only via system tools or `./run logs`.

## Component Interaction
- ShareExtensionManager reads inventory and API key, calls ProcessingManager.
- ProcessingManager forms the request, calls LLMAPIClient.
- LLMAPIClient sends HTTP POST to OpenAI, parses the response via ResponseParser.
- ClipboardManager copies the result to UIPasteboard.
- If the operation has resultMode `.display` (Explain) — the result is saved and displayed in the view, not copied to the clipboard.
- All actions are logged via LogManagerShared.
- ViewModel читает и пишет настройки через AppSettingsManager.shared.
- Операции (SummarizeOperation, ExplainOperation и др.) получают язык только через AppSettingsManager.shared.nativeLanguage.
- Смена языка в настройках немедленно отражается в UI, но применяется глобально только после Save.

## Error Handling
- All errors (Keychain, network, parsing, clipboard) are handled with an Alert.
- Retries for network errors (exponential backoff).
- API key masking in logs.
- In case of key access errors — prompt to open settings.
- Все операции выбрасывают NSError с описанием при ошибках входных данных.
- AppSettingsManager логирует все изменения настроек через LogManagerShared.

## Testing Strategy
- Unit tests for all managers and models.
- UI tests for all main scenarios, including Explain (display) and clipboard operations.
- Checks that Explain displays the result, and other operations copy to the clipboard.
- Coverage ≥ 80% for key modules.
- Unit-тесты проверяют корректность смены языка, генерации промптов, сериализации параметров операций.
- Добавлен тест, гарантирующий, что смена языка влияет на promptTemplate во всех операциях.

## Share Extension Architecture
- All managers are injected via DI, including OSLogManagerShared.
- Logging of all actions and errors, key masking.
- Text limit: 5000 characters, enforced in UI and manager.
- Timeouts: 15 seconds per request, 30 seconds total limit.
- Error handling: all scenarios covered (no text, limit, no consent, invalid key, network, parsing, clipboard, cancel).
- Covered by unit and UI tests (display, selection, saving color, result processing modes).
- CI/CD implements automatic extension size check (Archive + size report, fail if >20 MB).

### Interaction Diagram
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
  ShareExtension -->|resultMode .display| ShareExtensionView[ShareExtensionView: Display Result]
```

## Timeout Mechanism
- Processing timeout is implemented only at the ShareExtensionViewModel level (default 30 seconds, can be overridden in tests).
- ShareExtensionManager does not implement a timeout, only business logic for processing and errors.
- In unit tests, the ViewModel timeout is set via processingTimeoutSeconds.

## Operation Color & ResultMode
- InventoryOperation extended with colorHex property (hex color from palette).
- Added resultMode (clipboard/display) for operations.
- InventoryOperation serialization/deserialization supports colorHex and result processing mode.
- UI (HomeView, ShareExtensionView) displays operation color and correctly handles clipboard/display modes.
- For Explain, the result is displayed in a scrollable popup window.
- Covered by unit and UI tests (display, selection, saving color, result processing modes).
- The correct operation no longer contains the stylePreservationLevel parameter, always uses the maximum style preservation level.
- UI does not display elements for selecting style preservation level.

## Onboarding Flow
- CraftifyApp uses global AppState (ObservableObject), which stores the user's consent flag.
- If consent is not given, HowToUseView with a checkbox and consent button is shown.
- After consent, the main HomeView screen is automatically displayed.
- Consent is stored in App Group UserDefaults via ConsentManager.

## UI Architecture
- All main content (title, result, list of operations) is placed inside a ScrollView.
- The close button is fixed at the bottom via `.safeAreaInset(edge: .bottom)`, always available to the user.
- Overlays (progress indicator, toast) are implemented via ZStack and do not interfere with main content interaction.
- This approach ensures:
    - UX: the button is always available, even with long content
    - Content is not overlapped by the button
    - Accessibility support and adaptation to different devices
- All changes are covered by unit and UI tests, ensuring stable behavior.

## Localization
- **Localization only at the UI level**: All strings displayed to the user must be localized only in the views (MainApp, ShareExtension), not inside models, enums, or business logic in the Common module.
- **Models and enums in Common** must return only rawValue or identifier, not a localized string.
- **Reason**: SwiftGen generates a separate L10n for each target, and direct use of L10n in Common leads to visibility errors and conflicts. Localization at the UI level ensures correct operation and consistency.
- **Recommendation**: If you need to get a string for an enum/model, always do it via a function/mapping in the UI layer.

## Activation Rules
- Share Extension is activated for data types: text (public.text) and URL (public.url).
- This is set via NSExtensionActivationRule in Project.swift (Tuist):
  - SUBQUERY (... ANY $attachment.registeredTypeIdentifiers UTI-CONFORMS-TO "public.text" || ANY $attachment.registeredTypeIdentifiers UTI-CONFORMS-TO "public.url")
- Allows sharing both text and links via the "Share" menu.
- Both types are processed as plain text, with priority given to text.

## Style Centralization
- All style parameters for buttons (colors, radius, padding) are centralized in CraftifyButtonConstants (src/Common/Sources/CraftifyButtonConstants.swift).
- The color palette for operations is centralized in ColorPaletteConstants (src/Common/Sources/ColorPaletteConstants.swift) and used in all ViewModels and Views.
- This approach ensures interface consistency and simplifies maintenance.

## Target Dependency Isolation
- Production targets (MainApp, ShareExtension) must not depend on test-only packages or targets.
- Use `embedAppExtensions` to include extensions in the app bundle, not `dependencies`.
- Only include code in `dependencies` that is directly used by the target.
- Test dependencies (ViewInspector, XCTest, etc.) must be listed only in UnitTest targets.
- This prevents accidental autolinking of test frameworks and ensures clean, production-ready builds.

## References
- [Project Overview](project.md)
- [Implementation](implementation.md)
- [File Structure](file_structure.md)
- [Developer Manual](developer-manual.md)
- [User Manual](user-manual.md)

## Project Structure and Build System
- The project structure, targets, dependencies, and resources are fully described in Project.swift and Workspace.swift (Tuist manifests).
- No .xcodeproj or .xcworkspace files are tracked in VCS; they are generated on demand via tuist generate.
- All configuration is code-based and reproducible, supporting CI/CD and DevOps best practices.
- Manual editing of Xcode project files or use of XcodeGen is prohibited (all configuration is in Project.swift).
- All build, test, and code generation steps are automated via ./run scripts and Tuist.

## Benefits of Tuist-based Architecture
- Single source of truth for project structure and configuration
- Easy onboarding and reproducible builds
- Full automation for CI/CD pipelines
- No manual or GUI-based configuration drift
