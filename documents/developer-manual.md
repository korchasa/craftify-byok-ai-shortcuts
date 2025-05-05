# Craftify Developer Manual

## Table of Contents
- [Craftify Developer Manual](#craftify-developer-manual)
  - [Table of Contents](#table-of-contents)
  - [Installing Dependencies](#installing-dependencies)
  - [Building the Project](#building-the-project)
  - [Running Tests](#running-tests)
  - [Linting and Formatting](#linting-and-formatting)
  - [CI/CD](#cicd)
  - [Deployment](#deployment)
  - [Testing and CI Results](#testing-and-ci-results)
  - [Processing Timeout Testing](#processing-timeout-testing)
  - [Retrieving Logs](#retrieving-logs)
  - [Operation Color \& ResultMode](#operation-color--resultmode)
  - [Share Extension UI](#share-extension-ui)
  - [Share Extension Activation for URLs](#share-extension-activation-for-urls)
  - [Button Style Guide](#button-style-guide)
    - [Button Style Usage Guidelines](#button-style-usage-guidelines)
  - [Dependency and Test Isolation](#dependency-and-test-isolation)
  - [References](#references)

---

## Installing Dependencies
1. Install all required CLI tools with:
   ```sh
   ./run init
   ```
   This installs: xcodegen, swiftlint, swiftformat, xcbeautify, swiftgen (via Homebrew).

## Building the Project
- Generate the project: `xcodegen`
- Build: `./run build`

## Running Tests
- Unit and UI tests: `./run check`
- Coverage is checked automatically in CI

## Linting and Formatting
- Lint: `./run lint`
- Format: `./run format`

## CI/CD
- All checks and builds are automated via GitHub Actions (`.github/workflows/ci.yml`).
- ShareExtension size and test coverage (≥ 80%) are required for successful builds.

## Deployment
- Release build and publishing via Fastlane (see repository instructions).
- Signing and provisioning automated via Fastlane `match`.

## Testing and CI Results
- All instructions for running and testing are up-to-date.
- Test coverage and ShareExtension size are automatically checked in CI.

## Processing Timeout Testing
- Timeout is implemented only in ShareExtensionViewModel (default 30 seconds).
- In unit tests, the ViewModel timeout can be overridden via `processingTimeoutSeconds`.
- In E2E tests, ShareExtensionManager checks only processing errors and successes, not timeout.

## Retrieving Logs
To view logs for the app and extension, use Unified Log (os_log, subsystem: Internal, message + metadata only):
```sh
./run logs
```
The command outputs logs from Unified Log (os_log) for the last 24 hours, filtered by subsystem Internal, MainApp, and ShareExtension, all levels. Log export is not supported.

To change the period, use log show options, e.g.:
```sh
log show --predicate 'subsystem == "Internal"' --style syslog --last 2h
```

## Operation Color & ResultMode
- `InventoryOperation` extended with `colorHex` (hex color code).
- All operations now support a result processing mode (`resultMode`):
  - `.clipboard`: result is copied to the clipboard (default)
  - `.display`: result is shown in a popup window (used for Explain)
- For tests: InventoryManagerStub supports `colorHex` and `resultMode`.
- Coverage: unit tests (InventoryOperation, InventoryManager, result modes), UI tests (Add/EditOperationView, ShareExtensionView), e2e tests (ShareExtensionView, Explain).

## Share Extension UI
- Main UI is implemented in `src/ShareExtension/Sources/ShareExtensionView.swift`
- Close button is fixed at the bottom via `.safeAreaInset`, always accessible
- All other content is in a ScrollView
- All changes are covered by unit and e2e tests
- Linter and formatter pass without errors

## Share Extension Activation for URLs
- Share Extension is activated for data types: text (public.text) and URL (public.url).
- This is set via NSExtensionActivationRule in project.yml (XcodeGen):
  - SUBQUERY (... ANY $attachment.registeredTypeIdentifiers UTI-CONFORMS-TO "public.text" || ANY $attachment.registeredTypeIdentifiers UTI-CONFORMS-TO "public.url")
- After generating the project via `./run generate`, the extension is available for sharing links and text.
- Both types are processed as plain text, with priority given to text.
- Covered by unit and e2e tests.

## Button Style Guide
- Use only `CraftifyButtonConstants` for all button parameters (colors, radius, padding, scale).
- Use only `ColorPaletteConstants.palette` for color palette.
- Do not define local constants for these parameters in individual views or view models.
- Example usage:
```swift
Button(action: ...) {
    Text("...")
}
.buttonStyle(CraftifyPrimaryButtonStyle())
.padding(.horizontal, CraftifyButtonConstants.horizontalPadding)
.padding(.bottom, CraftifyButtonConstants.bottomPadding)
.cornerRadius(CraftifyButtonConstants.cornerRadius)
```

### Button Style Usage Guidelines
- **Primary**: For main actions (save, confirm, continue). Use `.buttonStyle(CraftifyPrimaryButtonStyle())`.
- **Secondary**: For secondary actions (cancel, extra options). Use `.buttonStyle(CraftifySecondaryButtonStyle())`.
- **Cancel**: For cancel, close, or return — use secondary style with white text.
- **Destructive**: For dangerous actions (delete, reset) use secondary style with `.foregroundColor(.red)` or `.tint(.red)`.
- **Do not create local ButtonStyle** — only use centralized styles.

## Dependency and Test Isolation
- Production targets (MainApp, ShareExtension) must not depend on test-only packages or targets.
- Use `embedAppExtensions` for including extensions, not `dependencies`.
- Test dependencies (ViewInspector, XCTest, etc.) must be listed only in UnitTest targets.
- If you encounter linker errors related to test frameworks, run `./run full-clean` and check your target dependencies.

## References
- [Project Overview](project.md)
- [Architecture](architecture.md)
- [Implementation](implementation.md)
- [File Structure](file_structure.md)
- [User Manual](user-manual.md)

- Для поддержки нового языка добавьте его в массив SupportedLanguages.all (src/Common/Sources/Models/SupportedLanguages.swift). Для промптов LLM всегда используется englishName.