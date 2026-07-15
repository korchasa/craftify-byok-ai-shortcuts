# SRS

## 1. Intro

- **Desc:** Functional requirements for Craftify (BYOK iOS text-processing app: MainApp + ShareExtension + Common).

## 3. Functional Reqs

### FR-UX.L10N-CLEANUP: Localization cleanup and CI key-parity gate [ANC:fr:ux.l10n-cleanup]

- **Description:** No mixed-language or untranslated user-facing strings; key sets identical across all 11 locales in all three bundles (MainApp, ShareExtension, Common); CI step in `./run check` fails on key-set divergence.
- **Tasks:** [REF:task:2026-07-ux-improvement-backlog | ux-improvement-backlog]
- **Acceptance:** `run::check_localization (script step, key-set diff per bundle)` | `./run check`
- **Status:** [x]

### FR-UX.SHEET-HEIGHT: Adaptive share-extension sheet height [ANC:fr:ux.sheet-height]

- **Description:** Share-extension sheet fits its content (operations grid) and grows to `.large()` when a result is displayed; iPad popover is ~360–400pt wide, not 180pt.
- **Tasks:** [REF:task:2026-07-ux-improvement-backlog | ux-improvement-backlog]
- **Acceptance:** `src/ShareExtension/UnitTests/ShareExtensionViewHeightTests.swift::testDetentGrowsWithOperationsAndResult` | `./run check`
- **Status:** [x]

### FR-UX.DYNAMIC-TYPE: Dynamic Type support [ANC:fr:ux.dynamic-type]

- **Description:** All app and extension text scales with the system font size setting; layouts stay usable at accessibility sizes (capped where needed).
- **Tasks:** [REF:task:2026-07-ux-improvement-backlog | ux-improvement-backlog]
- **Acceptance:** `src/MainApp/UnitTests/FontCraftifyTests.swift::testCraftifyFontsUseTextStyles` | `./run check`
- **Status:** [x]

### FR-UX.STAGED-PROGRESS: Staged progress messages during processing [ANC:fr:ux.staged-progress]

- **Description:** During processing the extension shows the current stage — "Loading page…" while fetching a URL, "Asking the model…" during the LLM call — localized in 11 locales.
- **Tasks:** [REF:task:2026-07-ux-improvement-backlog | ux-improvement-backlog]
- **Acceptance:** `src/ShareExtension/UnitTests/ShareExtensionViewModelTests.swift::testProcess_PublishesStages` | `./run check`
- **Status:** [x]

### FR-UX.MASKED-KEY: Masked API key in Settings with Change/Delete actions [ANC:fr:ux.masked-key]

- **Description:** Settings shows the stored key only masked with Change/Delete actions; the edit field never pre-fills the real key.
- **Tasks:** [REF:task:2026-07-ux-improvement-backlog | ux-improvement-backlog]
- **Acceptance:** `src/MainApp/UnitTests/SettingsViewModelTests.swift::testBeginEditing_StartsEmptyAndNeverExposesStoredKey` | `./run check`
- **Status:** [x]

### FR-UX.RETRY: Retry button in error alert for transient errors [ANC:fr:ux.retry]

- **Description:** Transient errors (network, rate limit, timeout, processing) show a Retry button in the alert that re-runs the same operation; non-transient errors do not.
- **Tasks:** [REF:task:2026-07-ux-improvement-backlog | ux-improvement-backlog]
- **Acceptance:** `src/ShareExtension/UnitTests/ShareExtensionViewModelTests.swift::testRetry_ReprocessesLastOperationOnlyForTransientErrors` | `./run check`
- **Status:** [x]

### FR-UX.MODEL-SELECT: Per-provider model selection in Settings [ANC:fr:ux.model-select]

- **Description:** User can pick the model per provider in Settings and during onboarding. The list is fetched live from the provider's `/v1/models` endpoint with substring search; there is no static catalog and no free-text field. A catalog default is preselected; if the list fails to load, the stored choice remains and a retry is offered. Choice persists per provider and is used by the extension; an unknown model surfaces a dedicated "change model" error (OpenRouter today).
- **Tasks:** [REF:task:2026-07-ux-improvement-backlog | ux-improvement-backlog]
- **Acceptance:** `src/MainApp/UnitTests/SettingsViewModelTests.swift::testModelSelection_PersistsPerProvider` | `./run check`
- **Status:** [x]
