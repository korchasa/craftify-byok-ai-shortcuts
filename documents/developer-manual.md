# Craftify Developer Manual

## Installing Dependencies
1. Install all required CLI tools with a single command:
   ```sh
   ./run init
   ```
   This will install via Homebrew: xcodegen, swiftlint, swiftformat, xcbeautify, swiftgen.

## Building the Project
- Generate the project: `xcodegen`
- Build: `./run build`

## Running Tests
- Unit and UI tests: `./run test`
- Coverage report: generated automatically in CI
- Mandatory requirement: all key user scenarios must be covered by end-to-end tests (E2E), including edge cases and negative scenarios.

### Important: Running Tests for iOS
To run tests manually, use the command with an explicit simulator:
```
xcodebuild -scheme Common -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 14,OS=16.4' test
```
This avoids the error "CommonTests does not support My Mac's platform: com.apple.platform.macosx".

## Linting and Formatting
- Style check: `./run lint`
- Formatting: `./run format`

## CI/CD
- All checks and builds are automated via GitHub Actions (`.github/workflows/ci.yml`)
- Share Extension size check and test coverage ≥ 80% are required for a successful build

## Deployment
- Release build and publishing via Fastlane (see repository instructions)
- Code signing and provisioning are automated via Fastlane `match`

## Testing and CI Results
- All tests (unit, UI, E2E) for Share Extension pass successfully.
- Instructions for running and testing are up to date.
- Test coverage and Share Extension size are automatically controlled in CI.

## Processing Timeout Testing
- Processing timeout is implemented only in ShareExtensionViewModel (default 30 seconds).
- For unit tests, the ViewModel timeout can be overridden via the processingTimeoutSeconds property.
- In E2E tests, ShareExtensionManager does not test timeout, only processing errors and successes.

- Do not edit Info.plist and entitlements directly. All changes must be made only through project.yml, which is processed by XcodeGen.

## Retrieving Logs

To view the application and extension logs, use the unified log (os_log):

```sh
./run logs
```

The command outputs logs from the unified log (os_log) for the last 24 hours, filtering by the subsystem "dev.korchasa.Craftify" in JSON format.

To change the period, use the log show options, for example:
```sh
log show --predicate 'subsystem == "dev.korchasa.Craftify"' --style json --last 2h
```

## Operation Color: Developer Notes
- InventoryOperation расширена свойством colorHex (hex-код цвета).
- Для тестов: InventoryManagerStub поддерживает colorHex.
- Покрытие: unit-тесты (InventoryOperation, InventoryManager), UI-тесты (Add/EditOperationView), e2e-тесты (ShareExtensionView).
- Для проверки UI: используйте ShareExtensionViewUITests.swift.