# Current State (April 2024)

- Error handling is now fully centralized via UserFacingError in both MainApp and ShareExtension.
- All user-facing errors are localized (en/ru) and provide actionable advice.
- Alert logic in ShareExtensionView is improved for reliability and user experience.
- Logging uses English messages for consistency across modules.
- Tests cover all error branches, including race conditions between error and timeout.
- FetchError and UserFacingError have been refactored and relocated for clarity.
- All changes are covered by unit and UI tests; project is stable and up to date.
- **2024-06-09: Major refactoring — all test targets and configs removed, dead code deleted, Periphery added to lint, interface and documentation simplified.**

# Craftify User Manual

---

## Getting Started
1. Open Craftify after installation.
2. On first launch, review the instructions and provide consent for text processing (checkbox).
3. Add desired operations (translate, simplify, correct, explain) via HomeView.
4. Enter your OpenAI API key in SettingsView.
5. To process text:
   - Select text in any app.
   - Invoke Craftify via the "Share" menu.
   - Choose the desired operation.
   - Receive the result:
     - For most operations, the result is automatically copied to the clipboard (with notification).
     - For Explain, the result is displayed directly in a scrollable popup window.

## Processing Result Modes
- Each operation supports a result processing mode:
  - **Clipboard**: result is copied to the clipboard (default for all operations).
  - **Display**: result is shown in a popup window (used for Explain).
- For Explain, the result is not copied automatically, but shown in the extension window.

## Testing
- All main scenarios are tested automatically (unit, UI), including Explain (display) and clipboard operations.
- For manual testing: use the Share Extension with different text types and parameters, check both modes (copy and display).

## Build and Deployment
- For self-building: follow instructions in [developer-manual.md](developer-manual.md).
- For updates: use App Store or TestFlight (if available).

## Notes
- All data (key, inventory) is stored only on the device.
- A valid OpenAI API key is required.
- The app does not store request history or analyze clipboard content.

## User Testing Results
- All user scenarios for the Share Extension are tested and work as documented.
- Edge-case scenarios (no text, too long text, network errors, invalid key, etc.) are handled correctly.
- Verified that Explain displays the result, and other operations copy to the clipboard.

## What's New in Share Extension
- Support for all main operations (translate, simplify, correct, explain) with parameters.
- Automatic text length check and processing block if limit exceeded.
- All errors (no text, too long, network errors, invalid key, clipboard errors) are handled with clear messages.
- Result:
  - For most operations — copied to clipboard and confirmed by notification.
  - For Explain — displayed in a scrollable popup window.
- All actions and errors are logged (FIFO, view via `./run logs`).

## Instruction Relevance
- Build, test, and update instructions are always current in [developer-manual.md](developer-manual.md).
- App structure and documentation fully match the current project state.
- **2024-06-09: All documentation updated to reflect the removal of test targets, dead code, and interface simplification.**

## Processing Time Limit
- If text processing takes too long (over 30 seconds), a timeout message appears.
- Timeout is implemented only in the Share Extension. No time limit in the main app.

## Log Viewing
All actions and errors are logged via Unified Log (os_log, subsystem: Internal, message + metadata only). To view logs, use:
```sh
./run logs
```
Logs are filtered by subsystem Internal, all levels, MainApp and ShareExtension. Log export is not supported; view only via system tools (Console.app, log stream) or `./run logs`.

## Operation Color Selection
- When adding or editing an operation, you can select a color from the palette. The color is shown on the operation card on the main screen and in the Share Extension.
- The correct operation always preserves style at maximum; the user cannot select the style preservation level.

## Welcome Screen and Consent
On first launch, Craftify displays a welcome screen with instructions and a consent checkbox. Until the user checks the box and presses "Done", app features are unavailable. After consent, the main screen opens automatically. Consent is saved and not requested again on subsequent launches.

## Using the Share Extension
- The close button is always available at the bottom, regardless of content length.
- All other content (operations, result) is scrollable if it does not fit on the screen.
- The button does not overlap content, even with lots of content.
- The interface is adapted for all devices and supports accessibility.
- All actions are tested, stability is guaranteed.

## Sharing Links (URLs)
- You can now share links (URLs) to Craftify via the "Share" menu from any app.
- Just select "Share" → Craftify, and the link will be processed as plain text.
- If both text and a link are shared, text takes priority.
- Length limit (5000 characters) applies to links as well.

## Unified Button Styles
All buttons in the application have a unified look and feel:
- Consistent color scheme
- Rounded corners
- Uniform padding and spacing
- Responsive press effect

This ensures a predictable and visually pleasing experience across all screens.

## Production Build Safety
- The application is built so that no test dependencies (ViewInspector, XCTest, etc.) are included in the production app or extension.
- If you encounter build or linker errors, run `./run clean` and rebuild.

## References
- [Project Overview](project.md)
- [Architecture](architecture.md)
- [Implementation](implementation.md)
- [File Structure](file_structure.md)
- [Developer Manual](developer-manual.md)

## Additional Notes
- In the app settings, you can select the native language from the full list of supported languages (ISO-639-1 and artificial languages). This language will be used by default for operations Summarize and Explain.
- For the Translate operation, this same list of languages is also available.

## Using Craftify
- To change the language of the interface and operations, open Settings, select the desired language from the dropdown list, and click Save. The language will change in all operations only after saving.
- All operations (Summarize, Explain, etc.) use only the current language from the settings, selected in Settings.
- After changing the language, new operations immediately use the new value, without the need to restart the application.

## Logs of settings changes
- All settings changes (including language) are recorded in the system log and can be analyzed via ./run logs.

## How to test language change
1. Open Settings, select a new language, click Save.
2. Perform any operation (Summarize, Explain, etc.) — the result will be in the new language.
3. To return to the previous language, repeat the steps.

## How to build and run
- For quick testing: `./run check`
- For running on a simulator: `./run sim`
- For viewing logs: `./run logs`

## How to update settings
- All settings are centralized in AppSettingsManager and saved in App Group, accessible from MainApp and ShareExtension.
- Changes take effect only after clicking Save in Settings.

## Appearance
- The text color of buttons always matches the application theme, as it is centrally set through the palette.