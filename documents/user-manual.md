# Craftify User Manual

## How to Use the Application
1. Open Craftify after installation.
2. On first launch, review the instructions and give consent for text processing (checkbox).
3. Add the required operations (translation, simplification, correction, explanation) via HomeView.
4. Enter your OpenAI API key in SettingsView.
5. To process text:
   - Select text in any application.
   - Invoke Craftify via the Share menu.
   - Choose the desired operation.
   - Receive the result—it will be automatically copied to the clipboard.

## Testing
- All main scenarios are tested automatically (mandatory requirement: all key user scenarios are covered by end-to-end tests, including edge cases and negative scenarios).
- For manual testing: use the Share Extension with different types of text and parameters.

## Build and Deployment
- For self-building: follow the instructions in developer-manual.md.
- For updates: use the App Store or TestFlight (if available).

## Notes
- All data (key, inventory) is stored only on the device.
- A valid OpenAI API key is required for operation.
- The app does not save request history and does not analyze clipboard contents.

## User Testing Results
- All user scenarios for the Share Extension have been tested and work according to the documentation.
- Edge-case scenarios (no text, text too long, network errors, invalid key, etc.) are handled correctly.

## What's New in Share Extension
- Support for all main operations (translation, simplification, correction, explanation) with parameters.
- Automatic text length check and blocking processing if the limit is exceeded.
- All errors (no text, text too long, network errors, invalid key, clipboard errors) are handled with clear messages.
- The result is always copied to the clipboard and confirmed by a notification.
- All actions and errors are logged (FIFO, log export available in the main app).

## Instruction Relevance
- Instructions for building, testing, and updating are always up to date in developer-manual.md.
- The structure of the app and documentation fully matches the current state of the project.

## Processing Time Limit
- If text processing takes too long (over 30 seconds), a timeout message will appear.
- The timeout is implemented only in the Share Extension. The main app does not apply a time limit.

## Log Viewing
All actions and errors of the application are logged through the unified log (os_log). To view the logs, use the command:
```sh
./run logs
```
Log export is not supported. Logs are only available through system tools (Console.app, log stream).