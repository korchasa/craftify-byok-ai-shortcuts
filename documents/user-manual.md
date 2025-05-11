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

## Start
1. Open app
2. On 1st launch: review, consent (checkbox)
3. Add ops (translate, simplify, correct, explain) via HomeView
4. Enter OpenAI API key in SettingsView
5. To process text:
   - Select text in any app
   - Share → Craftify
   - Choose op
   - Result:
     - Most ops: auto-copy to clipboard (notify)
     - Explain: show in popup

## Result Modes
- Each op: resultMode
  - Clipboard: copy (default)
  - Display: popup (Explain)

## Test
- All main scenarios: auto-tested (unit, UI)
- Manual: ShareExt, try text types/params, check both modes

## Build/Deploy
- Build: see [developer-manual.md](developer-manual.md)
- Update: App Store/TestFlight

## Data
- All data (key, inventory): device only
- OpenAI API key required
- No request history/clipboard analysis

## User Test Results
- All ShareExt scenarios tested
- Edge cases (no text, too long, network error, invalid key, etc.): handled
- Explain: shows result; others: copy

## ShareExt: What's New
- All main ops (translate, simplify, correct, explain) + params
- Auto text length check, block if limit
- All errors: clear messages
- Result:
  - Most: copy + notify
  - Explain: popup
- All actions/errors logged (FIFO, `./run logs`)

## Instruction Relevance
- Build/test/update: always current in [developer-manual.md](developer-manual.md)
- App structure/docs match state

## Timeout
- If processing >30s: timeout message
- Timeout: only in ShareExt

## Logs
- All actions/errors: Unified Log (os_log, subsystem: Internal)
- View: `./run logs` (filter: Internal, MainApp, ShareExt)
- No export

## Op Color
- Add/edit op: select color from palette
- Color shown on op card (main, ShareExt)
- Correct: always max style

## Welcome/Consent
- 1st launch: welcome, consent checkbox
- Until checked: features unavailable
- After: main screen auto-opens
- Consent saved, not re-asked

## ShareExt UI
- Close: always at bottom
- All content: scrollable
- Button never overlaps content
- Adapted for all devices, accessibility
- All tested

## Share Links
- Share links (URLs) via Share menu
- If both text+link: text priority
- 5000 char limit

## Button Styles
- Unified: color, corners, padding, press effect
- Consistent across screens

## Prod Build Safety
- No test deps in prod app/ext
- Build/link error: `./run clean` + rebuild

## References
- [Project Overview](project.md)
- [Architecture](architecture.md)
- [Implementation](implementation.md)
- [File Structure](file_structure.md)
- [Developer Manual](developer-manual.md)

## Language
- Settings: select language (ISO-639-1 + artificial)
- Used for Summarize, Explain, Translate
- Change: open Settings, select, Save
- All ops use current language
- Change applies instantly, no restart

## Logs of Settings
- All changes (incl. language): logged, view via `./run logs`

## Test Language Change
1. Open Settings, select new language, Save
2. Run any op: result in new language
3. To revert: repeat

## Build/Run
- Quick: `./run check`
- Simulator: `./run sim`
- Logs: `./run logs`

## Update Settings
- All settings: AppSettingsManager, App Group
- Changes: only after Save

## Appearance
- Btn text color: always matches theme, set via palette