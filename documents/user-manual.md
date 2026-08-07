# Craftify User Manual

## Start
1. Open app
2. On first launch: review full Privacy Policy and tap **Accept & Continue** to grant consent
3. Add operations (Translate, Simplify, Correct, Explain, Summarize) via HomeView
4. Choose **LLM provider** (OpenAI or Claude) and enter the corresponding **API key** in SettingsView
5. To process text:
   - Select text in any app
   - Share → Craftify
   - Choose op
   - Result:
     - Most ops: auto-copy to clipboard (notify)
     - Explain & Summarize: show in popup

## Result Modes
- Each op: resultMode
  - Clipboard: copy (default)
  - Display: popup (Explain, Summarize)

## Test
- All main scenarios: auto-tested (unit, UI)
- Manual: ShareExt, try text types/params, check both modes

## Build/Deploy
- Build: see [developer-manual.md](developer-manual.md)
- Update: App Store/TestFlight

## Data
- All data (key, inventory): device only
- LLM API key required for the selected provider
- No request history/clipboard analysis

## User Test Results
- All ShareExt scenarios tested
- Edge cases (no text, too long, network error, invalid key, etc.): handled
- Explain: shows result; others: copy

## ShareExt: What's New
- All main ops (translate, simplify, correct, explain, summarize) + params
- Auto text length check, block if limit
- All errors: clear messages
- Result:
  - Most: copy + notify
  - Explain & Summarize: popup
- All actions/errors logged (FIFO, `deno task logs`)

## Instruction Relevance
- Build/test/update: always current in [developer-manual.md](developer-manual.md)
- App structure/docs match state

## Timeout
- If processing >30s: timeout message
- Timeout: only in ShareExt

## Logs
- All actions/errors: Unified Log (os_log, subsystem: Internal)
- View: `deno task logs` (filter: Internal, MainApp, ShareExt)
- No export

## Op Color
- Add/edit op: select color from palette
- Color shown on op card (main, ShareExt)
- Correct: always max style

## Welcome/Consent
- On first launch, HowToUseView shows the full Privacy Policy followed by an **Accept & Continue** button.
- Craftify features remain unavailable until the user taps **Accept & Continue**.
- Once accepted, the main HomeView loads automatically and consent is stored (never re-asked).

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
- Build/link error: `deno task clean` + rebuild

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
- All changes (incl. language): logged, view via `deno task logs`

## Test Language Change
1. Open Settings, select new language, Save
2. Run any op: result in new language
3. To revert: repeat

## Build/Run
- Quick: `deno task check`
- Simulator: `deno task dev`
- Logs: `deno task logs`

## Update Settings
- All settings: AppSettingsManager, App Group
- Changes: only after Save

## Appearance
- Btn text color: always matches theme, set via palette