## Architecture Craftify

### General Scheme
- The main application (SwiftUI) and Share Extension use a common module Common (SwiftPM).
- Interaction between modules through App Group (UserDefaults) and Keychain Sharing.
- Logging through LogManagerShared (SPM), storing logs in the os log.

### Key Patterns
- MVVM + SwiftUI for UI and business logic.
- Dependency Injection for managers.
- FIFO for logs (limit of 1000 entries).

### Logging and Analytics

#### Log Architecture
- All logs are written through the system log (Unified Logging, os_log) via OSLogManagerShared. Log export is not supported, viewing is done through Console.app or log stream.
- LogManagerShared supports levels: debug, info, warning, error.
- API keys are always masked (only the first and last 4 characters are visible).
- Crash reporting is implemented through the New Relic SDK, integrated only into the main application (not in the Share Extension).
- The New Relic App Token is stored in Info.plist and is injected at runtime.
- No third-party SDKs for analytics or crash reporting are used in the Share Extension (minimum size, compliance with App Store).

#### Log Export and Retention Policy
- Log export is not supported (system log limitation). Logs can be viewed through Console.app or log stream.
- Crash reports are sent only from the main application via New Relic SDK.

#### Consequences
- Logs are available for diagnostics only through system tools.
- Crash analytics is available only for the main application through New Relic.
- Share Extension remains lightweight and meets privacy requirements.
- Log masking policy is implemented at the code level.

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
- Logging of all actions and errors, key masking.
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

## Timeout Mechanism for Text Processing
- The processing timeout is implemented only at the ShareExtensionViewModel level (default 30 seconds, can be overridden in tests).
- ShareExtensionManager does not implement a timeout, only the business logic for processing and errors.
- In unit tests, the ViewModel timeout is set through processingTimeoutSeconds.
- In E2E tests, ShareExtensionManager only checks for errors and successes in processing, but not the timeout.