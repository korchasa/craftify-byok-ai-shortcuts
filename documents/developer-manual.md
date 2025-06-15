# Current State (April 2024)

- Error handling is now fully centralized via UserFacingError in both MainApp and ShareExtension.
- All user-facing errors are localized (en/ru) and provide actionable advice.
- Alert logic in ShareExtensionView is improved for reliability and user experience.
- Logging uses English messages for consistency across modules.
- Tests cover all error branches, including race conditions between error and timeout.
- FetchError and UserFacingError have been refactored and relocated for clarity.
- All changes are covered by unit and UI tests; project is stable and up to date.

# Craftify Developer Manual

---

## Install
- `./run init`: install CLI tools (tuist, swiftlint, swiftformat, xcbeautify, swiftgen, periphery)

## Build
- `./run generate`: tuist, swiftgen
- `./run build`: build

## Test
- `./run check`: unit/UI tests, lint, format
- Coverage auto-checked in CI

## Lint/Format
- `./run lint`: lint
- `./run format`: format

## CI/CD
- All automated via GitHub Actions (`.github/workflows/ci.yml`)
- ShareExt size, coverage (≥80%) required
- Periphery in lint

## Deploy
- Release/publish: Fastlane
- Signing/provision: Fastlane match

## Timeout Test
- Only in ShareExtensionViewModel (30s, override in tests)
- ShareExtensionManager: only logic

## Logs
- `./run logs`: Unified Log (os_log, subsystem: Internal)
- Change period: `log show --predicate 'subsystem == "Internal"' --style syslog --last 2h`

## Operation Color & ResultMode
- InventoryOperation: colorHex
- All ops: resultMode (clipboard/display)
- Tests: InventoryManagerStub, InventoryOperation, Add/EditOperationView, ShareExtensionView

## ShareExt UI
- Main: `src/ShareExtension/Sources/ShareExtensionView.swift`
- Close: fixed bottom via .safeAreaInset
- All content: ScrollView
- All tested

## Activation for URLs
- ShareExt: public.text, public.url (NSExtensionActivationRule in Project.swift)
- Both: text priority
- All tested

## Button Style Guide
- Use only CraftifyButtonConstants for btn params (color, radius, padding, scale)
- Use only ColorPaletteConstants.palette for color
- No local consts in views/VMs
- Example:
```swift
Button(action: ...) {
    Text("...")
}
.buttonStyle(CraftifyPrimaryButtonStyle())
.padding(.horizontal, CraftifyButtonConstants.horizontalPadding)
.padding(.bottom, CraftifyButtonConstants.bottomPadding)
.cornerRadius(CraftifyButtonConstants.cornerRadius)
```
- **Primary**: main actions, `.buttonStyle(CraftifyPrimaryButtonStyle())`
- **GraySecondary**: cancel/extra, `.buttonStyle(GraySecondaryButtonStyle())`
- **Cancel**: secondary + white text
- **SettingsPrimary**: primary actions on Settings screen, `.buttonStyle(SettingsPrimaryButtonStyle())`
- **Destructive**: secondary + `.foregroundColor(.red)`
- No local ButtonStyle

## Dependency/Test Isolation
- Prod targets: no test-only deps
- Use embedAppExtensions, not deps
- Test deps: only in UnitTest targets

## References
- [Project Overview](project.md)
- [Architecture](architecture.md)
- [Implementation](implementation.md)
- [File Structure](file_structure.md)
- [User Manual](user-manual.md)

- To add new language: add to SupportedLanguages.all (src/Common/Sources/Models/SupportedLanguages.swift). LLM prompts: always englishName.
- Btn text color: set via palette.primaryButtonText()/secondaryButtonText() in calling code, not in buttonStyle.

- Для поддержки нового языка добавьте его в массив SupportedLanguages.all (src/Common/Sources/Models/SupportedLanguages.swift). Для промптов LLM всегда используется englishName.

- Цвет текста кнопок задается явно через palette.primaryButtonText()/secondaryButtonText() в вызывающем коде, а не внутри buttonStyle.