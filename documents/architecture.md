## Craftify Architecture

### General Scheme
- The main application (SwiftUI) and Share Extension use the shared Common module (SwiftPM).
- Interaction between modules is via App Group (UserDefaults) and Keychain Sharing.
- Logging is done via LogManagerShared (SPM), logs are stored in os log.
- All operations now support a result processing mode (resultMode):
  - `.clipboard` — the result is copied to the clipboard (default for all operations).
  - `.display` — the result is displayed in a popup window (used for Explain).

### Key Patterns
- MVVM + SwiftUI for UI and business logic.
- Dependency Injection for managers.
- FIFO for logs (limit 1000 entries).

### Logging and Analytics

#### Log Architecture
- All logs are written via the system log (Unified Logging, os_log, subsystem: Internal, message + metadata only) through OSLogManagerShared. Log export is not supported, viewing is via Console.app, log stream, or ./run logs.
- LogManagerShared supports levels: debug, info, warning, error. In production, only message + metadata are logged.
- API keys are always masked (only the first and last 4 characters are visible).
- Crash reporting is implemented via New Relic SDK (main app only).
- No third-party SDKs for analytics or crash reporting are used in the Share Extension (minimal size, App Store compliance).

#### Log Export and Retention Policy
- Log export is not supported (system log limitation). Viewing is only via system tools.
- Crash reports are sent only from the main app via New Relic SDK.

#### Consequences
- Logs are available only for diagnostics via system tools or ./run logs (filtered by subsystem Internal, all levels, MainApp and ShareExtension).
- Crash analytics — only for the main app.
- Share Extension remains lightweight and privacy-compliant.
- Key masking policy is implemented at the code level.

### Component Interaction
- ShareExtensionManager reads inventory and API key, calls ProcessingManager.
- ProcessingManager forms the request, calls LLMAPIClient.
- LLMAPIClient sends HTTP POST to OpenAI, parses the response via ResponseParser.
- ClipboardManager copies the result to UIPasteboard.
- If the operation has resultMode `.display` (Explain) — the result is saved and displayed in the view, not copied to the clipboard.
- All actions are logged via LogManagerShared.

### Error Handling
- All errors (Keychain, network, parsing, clipboard) are handled with an Alert.
- Retries for network errors (exponential backoff).
- API key masking in logs.
- In case of key access errors — prompt to open settings.

### Testing
- Unit tests for all managers and models.
- UI/E2E tests for all main scenarios, including Explain (display) and clipboard operations.
- Checks that Explain displays the result, and other operations copy to the clipboard.
- Coverage ≥ 80% for key modules.

### Results of Share Extension Implementation
- Architectural solutions (DI, logging, error handling, testability) are fully implemented as per documentation.
- All components and interactions match the description.
- Support for resultMode for operations.

### Share Extension: Final Architecture

- All managers are injected via DI, including OSLogManagerShared.
- Logging of all actions and errors, key masking.
- Text limit: 5000 characters, enforced in UI and manager.
- Timeouts: 15 seconds per request, 30 seconds total limit.
- Error handling: all scenarios covered (no text, limit, no consent, invalid key, network, parsing, clipboard, cancel).
- Covered by unit, UI, E2E tests (≥80%).
- CI/CD implements automatic extension size check (Archive + size report, fail if >20 MB).

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
  ShareExtension -->|resultMode .display| ShareExtensionView[ShareExtensionView: Display Result]
```

### Targets and Schemes

- MainApp
- MainAppUnitTests
- MainAppE2ETests
- ShareExtension
- ShareExtensionUnitTests
- ShareExtensionE2ETests
- CommonUnitTests
- CommonE2ETests
- ShareExtensionSizeReport

**Detailed descriptions of operations and prompts can be found in user-manual.md and developer-manual.md.**

## Timeout Mechanism for Text Processing
- Processing timeout is implemented only at the ShareExtensionViewModel level (default 30 seconds, can be overridden in tests).
- ShareExtensionManager does not implement a timeout, only business logic for processing and errors.
- In unit tests, the ViewModel timeout is set via processingTimeoutSeconds.
- In E2E tests, ShareExtensionManager checks only for errors and processing successes, not timeout.

### Operation Color & ResultMode Support
- InventoryOperation extended with colorHex property (hex color from palette).
- Added resultMode (clipboard/display) for operations.
- InventoryOperation serialization/deserialization supports colorHex and result processing mode.
- UI (HomeView, ShareExtensionView) displays operation color and correctly handles clipboard/display modes.
- For Explain, the result is displayed in a scrollable popup window.
- Covered by unit, UI, and e2e tests (display, selection, saving color, result processing modes).

- The correct operation no longer contains the stylePreservationLevel parameter, always uses the maximum style preservation level.
- UI does not display elements for selecting style preservation level.

### Onboarding (Welcome Screen Before Consent)
- CraftifyApp uses global AppState (ObservableObject), which stores the user's consent flag.
- If consent is not given, HowToUseView with a checkbox and consent button is shown.
- After consent, the main HomeView screen is automatically displayed.
- Consent is stored in App Group UserDefaults via ConsentManager.
- Covered by e2e test for the full flow: no consent → consent → transition to HomeView.

## Share Extension UI Architecture

- All main content (title, result, list of operations) is placed inside a ScrollView.
- The close button is fixed at the bottom via `.safeAreaInset(edge: .bottom)`, always available to the user.
- Overlays (progress indicator, toast) are implemented via ZStack and do not interfere with main content interaction.
- This approach ensures:
    - UX: the button is always available, even with long content
    - Content is not overlapped by the button
    - Accessibility support and adaptation to different devices
- All changes are covered by unit and e2e tests, ensuring stable behavior.

## Localization Features

- **Localization only at the UI level**: All strings displayed to the user must be localized only in the views (MainApp, ShareExtension), not inside models, enums, or business logic in the Common module.
- **Models and enums in Common** must return only rawValue or identifier, not a localized string.
- **Reason**: SwiftGen generates a separate L10n for each target, and direct use of L10n in Common leads to visibility errors and conflicts. Localization at the UI level ensures correct operation and consistency.
- **Example**:
    - CORRECT:
      ```swift
      // In Common model
      public enum ComplexityLevel: String, Codable, CaseIterable, Equatable { ... }
      // In UI:
      Text(labelForComplexityLevel(level))
      private func labelForComplexityLevel(_ level: ComplexityLevel) -> String {
          switch level {
          case .schoolchild: L10n.operationValueSchoolchild
          ...
          }
      }
      ```
    - INCORRECT:
      ```swift
      // In Common model
      public var displayName: String { L10n.operationValueSchoolchild } // do not do this!
      ```
- **Recommendation**: If you need to get a string for an enum/model, always do it via a function/mapping in the UI layer.
