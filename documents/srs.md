# SRS

## 1. Intro

- **Desc:** Functional requirements for Craftify (BYOK iOS text-processing app: MainApp + ShareExtension + Common).

## 3. Functional Reqs

### FR-UX.L10N-CLEANUP: Localization cleanup and CI key-parity gate [ANC:fr:ux.l10n-cleanup]

- **Description:** No mixed-language or untranslated user-facing strings; key sets identical across all 11 locales in all three bundles (MainApp, ShareExtension, Common); CI step in `deno task check` fails on key-set divergence.
- **Tasks:** [REF:task:2026-07-ux-improvement-backlog | ux-improvement-backlog]
- **Acceptance:** `run::check_localization (script step, key-set diff per bundle)` | `deno task check`
- **Status:** [x]

### FR-UX.SHEET-HEIGHT: Full-height share-extension sheet [ANC:fr:ux.sheet-height]

- **Description:** The share-extension sheet takes the whole screen: the shared text sits on the backdrop and the operations card is pinned to the bottom, mirroring the main screen where the tiles sit at the bottom. iPad popover is ~360–400pt wide, not 180pt, and takes a fixed share of the screen height.
- **Tasks:** [REF:task:2026-07-ux-improvement-backlog | ux-improvement-backlog]
- **Acceptance:** `src/ShareExtension/UnitTests/ShareExtensionViewHeightTests.swift::testPopoverHeightIsShareOfScreen` | `deno task check`
- **Status:** [x]

### FR-UX.DYNAMIC-TYPE: Dynamic Type support [ANC:fr:ux.dynamic-type]

- **Description:** All app and extension text scales with the system font size setting; layouts stay usable at accessibility sizes (capped where needed).
- **Tasks:** [REF:task:2026-07-ux-improvement-backlog | ux-improvement-backlog]
- **Acceptance:** `src/MainApp/UnitTests/FontCraftifyTests.swift::testCraftifyFontsUseTextStyles` | `deno task check`
- **Status:** [x]

### FR-UX.STAGED-PROGRESS: Staged progress messages during processing [ANC:fr:ux.staged-progress]

- **Description:** During processing the extension shows the current stage — "Loading page…" while fetching a URL, "Asking the model…" during the LLM call — localized in 11 locales.
- **Tasks:** [REF:task:2026-07-ux-improvement-backlog | ux-improvement-backlog]
- **Acceptance:** `src/ShareExtension/UnitTests/ShareExtensionViewModelTests.swift::testProcess_PublishesStages` | `deno task check`
- **Status:** [x]

### FR-UX.MASKED-KEY: Masked API key in Settings with Change/Delete actions [ANC:fr:ux.masked-key]

- **Description:** Settings shows the stored key only masked with Change/Delete actions; the edit field never pre-fills the real key.
- **Tasks:** [REF:task:2026-07-ux-improvement-backlog | ux-improvement-backlog]
- **Acceptance:** `src/MainApp/UnitTests/SettingsViewModelTests.swift::testBeginEditing_StartsEmptyAndNeverExposesStoredKey` | `deno task check`
- **Status:** [x]

### FR-UX.PROVIDER-ERRORS: Every provider response gets an actionable message [ANC:fr:ux.provider-errors]

- **Description:** Any refusal from OpenAI, Claude, Mistral or OpenRouter reaches the user as a localized message plus the action to take, never as "unknown error". Covered: invalid key (401), spent credits or quota (402 and 429 with a quota marker), denied access or unsupported region (403), moderation (403 with a moderation marker, `content_filter` finish reason), unknown model (404, and OpenRouter's 400 "is not a valid model ID"), context overflow (413, `context_length_exceeded`, "prompt is too long"), timeout (408, 504), rate limit (429), provider unavailable (500–599, including Claude's 529), plain rejection (other 400/422, with the provider's own explanation shown under the message), and an error delivered inside a 200 body. Classification lives in one place for all four providers; the Retry button is offered only for errors a retry can fix.
- **Tasks:** [REF:task:2026-08-provider-error-taxonomy | provider-error-taxonomy]
- **Acceptance:** `src/ShareExtension/UnitTests/ShareExtensionManagerTests.swift::testProcess_ProviderErrorKeepsItsUserFacingMessage` | `deno task check`
- **Status:** [x]

### FR-UX.RETRY: Retry button in error alert for transient errors [ANC:fr:ux.retry]

- **Description:** Transient errors (network, rate limit, timeout, parsing, provider unavailable) show a Retry button in the alert that re-runs the same operation; errors a retry cannot fix — invalid key, spent credits, denied access, moderation, context overflow, unknown model, rejected request — do not.
- **Tasks:** [REF:task:2026-07-ux-improvement-backlog | ux-improvement-backlog]
- **Acceptance:** `src/ShareExtension/UnitTests/ShareExtensionViewModelTests.swift::testRetry_ReprocessesLastOperationOnlyForTransientErrors` | `deno task check`
- **Status:** [x]

### FR-UX.MODEL-SELECT: Per-provider model selection in Settings [ANC:fr:ux.model-select]

- **Description:** User can pick the model per provider in Settings and during onboarding. The list is fetched live from the provider's `/v1/models` endpoint with substring search; there is no static catalog and no free-text field. A catalog default is preselected; if the list fails to load, the stored choice remains and a retry is offered. Choice persists per provider and is used by the extension; an unknown model surfaces a dedicated "change model" error for every provider [REF:fr:ux.provider-errors].
- **Tasks:** [REF:task:2026-07-ux-improvement-backlog | ux-improvement-backlog]
- **Acceptance:** `src/MainApp/UnitTests/SettingsViewModelTests.swift::testModelSelection_PersistsPerProvider` | `deno task check`
- **Status:** [x]

### FR-UX.OPERATION-TILES: The same operation tile on the home screen and the picker [ANC:fr:ux.operation-tiles]

- **Description:** The operations list in the app and the transformation picker in the share extension render every operation with one and the same tile — icon on the left, operation name, and the configured setting on a second line — laid out in the same two-column grid. The setting value goes through one shared localized formatter: summarize shows the localized label, never the canonical English string that goes into the prompt, and translate shows the bare language name. Whatever the user arranges in the app is what the extension shows.
- **Tasks:** [REF:task:2026-07-operation-tiles-on-both-screens | operation-tiles-on-both-screens]
- **Acceptance:** `src/Common/UnitTests/OperationDisplayTests.swift::testSummarizeShowsLocalizedLabelNotCanonicalValue` | `deno task check`
- **Status:** [x]

### FR-UX.TILE-ARRANGE: Arranging tiles on the home screen [ANC:fr:ux.tile-arrange]

- **Description:** The home screen is a grid of cells, not a list: every operation owns a cell, and gaps between occupied cells stay as the user left them. Cells are numbered from the bottom up, so the tiles the user reaches for sit under the thumb and new cells grow upwards. Tapping Edit puts the tiles into arrange mode: they wiggle, each grows a red minus badge, and any tile can be dragged onto any cell — an empty one takes it, an occupied one swaps. Holding a tile enters the same mode without the Edit button, and the very same hold carries on into the drag, exactly like an app icon on the iOS home screen — the user never presses twice. Every empty cell offers "+ Add", and the new operation lands in that exact cell. Deleting through the minus asks for confirmation first. The wiggle stops when the system Reduce Motion setting is on. Each operation carries a stable identifier and a stable cell that survive editing, so the arrangement belongs to the operation rather than to its place in the array, and the same arrangement — gaps included — is what the extension shows.
- **Tasks:** [REF:task:2026-07-operation-tiles-on-both-screens | operation-tiles-on-both-screens]
- **Acceptance:** `src/Common/UnitTests/OperationGridTests.swift::testCellsKeepGapsBetweenOccupiedSlots` | `deno task check` | `src/MainApp/UITests/OperationEditingUITests.swift::testLongPressDragMovesTileWithoutSecondPress` | `tuist test UITests --no-selective-testing --test-targets MainAppUITests/OperationEditingUITests`
- **Status:** [x]

### FR-UX.SHARE-INPUT-PREVIEW: Shared text visible above the transformation picker [ANC:fr:ux.share-input-preview]

- **Description:** Before choosing an operation, the share extension shows the text (or link) it is about to transform at the top of the sheet, under a localized uppercase caption that distinguishes selected text from a shared link. The preview is not clipped: it lays out in full on the backdrop above the operations card and scrolls when it does not fit.
- **Tasks:** [REF:task:2026-07-operation-tiles-on-both-screens | operation-tiles-on-both-screens]
- **Acceptance:** `src/ShareExtension/UnitTests/ShareExtensionViewModelTests.swift::testUpdateInputText_PublishesPreviewAndDetectsURL` | `deno task check`
- **Status:** [x]
