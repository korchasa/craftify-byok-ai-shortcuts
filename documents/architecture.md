# Craftify Architecture

## System Overview
- MainApp (SwiftUI) and Share Extension both use the shared Common module (SwiftPM).
- Modules interact via App Group (UserDefaults) and Keychain Sharing.
- Logging is centralized via LogManagerShared (SPM), using os_log.
- - A provider-agnostic factory (`LLMClientFactory`) resolves the current `LLMProvider` (e.g. **OpenAI**, **Claude**) stored in `AppSettingsManager.llmProvider` and returns the matching client (`OpenAIAPIClient`, `ClaudeAPIClient`, …).
- All operations support a result processing mode (`resultMode`):
  - `.clipboard`: result is copied to the clipboard (default)
  - `.display`: result is shown in a popup window (used for Explain and Summarize)

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
- Log entries now include only the first 48 characters of the system prompt (`systemPreview`) instead of the full template, reducing log noise and protecting user privacy.

## Component Interaction
- ShareExtensionManager reads inventory and API key, calls `ProcessingManager`.
- `ProcessingManager` asks `LLMClientFactory` for a concrete client that conforms to `LLMClienting`.
- The concrete client (`OpenAIAPIClient`, `ClaudeAPIClient`, …) executes the network request to the selected provider and returns the generated text.
- ClipboardManager copies the result to UIPasteboard.
- If the operation has resultMode `.display` (Explain or Summarize) — the result is saved and displayed in the view, not copied to the clipboard.
- All actions are logged via LogManagerShared.
- ViewModel читает и пишет настройки через AppSettingsManager.shared.
- Операции (SummarizeOperation, ExplainOperation и др.) получают язык только через AppSettingsManager.shared.nativeLanguage.
- Смена языка в настройках немедленно отражается в UI, но применяется глобально только после Save.

## Error Handling
- All errors (Keychain, network, parsing, clipboard) are handled with an Alert.
- Retries for network errors (exponential backoff).
- API key masking in logs.
- In case of key access errors — prompt to open settings.
- Provider responses are classified in one place — `LLMHTTPErrorMapper`; all four clients delegate both the error branch and the "200 with an error inside the body" case to it. Status code decides first; body markers (`error.code`, `error.type`, OpenRouter `metadata`, Mistral `detail`) only refine the ambiguous codes: 429 splits into rate limit vs spent quota, 403 into moderation vs permissions, 400/422 into context overflow, unknown model, moderation and plain rejection.
- `LLMAPIClientError` carries the taxonomy and answers two questions: `userFacingError` — which localized message and advice to show, `isRetryable` — whether a retry can change anything. Clients stop retrying non-retryable errors immediately, and `ShareExtensionViewModel` offers the Retry button by the same rule.
- `ShareExtensionManager.userFacingError(from:)` is the single conversion point from a thrown error to a user-facing one; without it provider errors degrade into "unknown error".
- The provider's own explanation (`providerDetail`) is appended under the message for rejected requests and unknown models — for those cases it is the only specific information the user has.
- Все операции выбрасывают NSError с описанием при ошибках входных данных.
- AppSettingsManager логирует все изменения настроек через LogManagerShared.

## Testing Strategy
- Unit tests cannot resolve user-facing strings: `Bundle(for:)` inside a unit-test target has no compiled `Localizable.strings`, so `UserFacingErrorKey.localized(in:)` returns the key itself and an assertion on the translated text fails even for a long-existing key. Assert message/advice **keys** instead; that the keys have translations is guaranteed by `check_localization` in `./run check`, which compares every locale against `en` in all three bundles and verifies that every `UserFacingErrorKey` raw value has a string in the extension's `en.lproj`.
- Unit tests for all managers and models.
- UI tests for all main scenarios, including Explain and Summarize (display) and clipboard operations.
- Checks that Explain and Summarize display the result, and other operations copy to the clipboard.
- Coverage ≥ 80% for key modules.
- Unit-тесты проверяют корректность смены языка, генерации промптов, сериализации параметров операций.
- Added a unit test that verifies a language switch correctly updates the system-level message generated by makeMessages() for every operation.
- **2024-06-09: All test targets and configs removed from Xcode project. Only production code remains. Dead code is now detected by Periphery in lint.**

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
  ProcessingManager --> LLMClientFactory[LLMClientFactory]
  LLMClientFactory -->|creates| ConcreteLLMClient[OpenAI / Claude Client]
  ConcreteLLMClient --> UIPasteboard[UIPasteboard]
  subgraph Shared
    LogManagerShared[Log Manager Shared]
  end
  ShareExtension & ProcessingManager & LLMClientFactory & ConcreteLLMClient & UIPasteboard -.-> LogManagerShared
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
- For Explain and Summarize, the result is displayed in a scrollable popup window.
- Covered by unit and UI tests (display, selection, saving color, result processing modes).
- The correct operation no longer contains the stylePreservationLevel parameter, always uses the maximum style preservation level.
- UI does not display elements for selecting style preservation level.

## Onboarding Flow
- CraftifyApp uses global AppState (ObservableObject), which stores the user's consent flag.
- On first launch, HowToUseView displays the full Privacy Policy text followed by an **Accept & Continue** button.
- The user must tap **Accept & Continue** to grant consent; after that, the main HomeView screen is automatically shown.
- Consent is stored in App Group UserDefaults via **ConsentManager** and is not requested again.

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
- Concrete ButtonStyle implementations now include: CraftifyPrimaryButtonStyle, GraySecondaryButtonStyle (generic cancel), and SettingsPrimaryButtonStyle (actions on Settings screen). All use constants from CraftifyButtonConstants.
- The color palette for operations is centralized in ColorPaletteConstants (src/Common/Sources/ColorPaletteConstants.swift) and used in all ViewModels and Views.
- This approach ensures interface consistency and simplifies maintenance.
- All buttons use a centralized palette for text and background color through Environment.
- The text color of the buttons is explicitly set through palette.primaryButtonText()/secondaryButtonText() in the calling code.

## Target Dependency Isolation
- Production targets (MainApp, ShareExtension) must not depend on test-only packages or targets.
- Use `embedAppExtensions` to include extensions in the app bundle, not `dependencies`.
- Only include code in `dependencies` that is directly used by the target.
- Test dependencies (ViewInspector, XCTest, etc.) must be listed only in UnitTest targets.
- This prevents accidental autolinking of test frameworks and ensures clean, production-ready builds.
- **2024-06-09: All test targets and their dependencies have been removed from the project.**

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

## App Icon
- MainApp ships an **iOS 26 Icon Composer bundle**: `src/MainApp/Resources/AppIcon.icon` (a folder with `icon.json` + `Assets/glyph.png`), referenced by `CFBundleIconName: "AppIcon"` and added as an explicit resource in Project.swift. `actool` compiles it into `Assets.car` and auto-derives the flat legacy renditions (120px iPhone, 152px iPad, 1024 marketing) that iOS 16–25 use — verified: `actool --minimum-deployment-target 16.0` emits `CFBundleIconFiles [AppIcon60x60, AppIcon76x76]` with no warnings.
- The icon is intentionally **flat, not glass**: every layer sets `"glass": false` and shadow/translucency are zeroed, so iOS 26 does not add the Liquid Glass sheen.
- Appearance colours are per-appearance via `fill-specializations`: white "C" in light, black "C" in dark, over the same turquoise `#00C0B6` background. The background fill is duplicated into the dark specialization on purpose — a plain solid `fill` is treated as light-only and would fall back to system gray in dark.
- `glyph.png` is only a **white alpha mask**; the manifest recolours it per appearance, so no separate dark PNG is needed.
- ShareExtension keeps the classic `AppIcon.appiconset` (an extension never shows a Liquid Glass home-screen icon).
- Sources live in `documents/`: `icon.svg` (flat letter-on-turquoise, feeds the ShareExtension appiconset) and `icon-glyph.svg` (transparent letter mask, feeds the `.icon` glyph). Regenerate all PNGs with `./run icons`.

## Benefits of Tuist-based Architecture
- Single source of truth for project structure and configuration
- Easy onboarding and reproducible builds
- Full automation for CI/CD pipelines
- No manual or GUI-based configuration drift
