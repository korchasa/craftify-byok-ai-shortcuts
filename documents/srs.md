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

- **Description:** All app and extension text scales with the system font size setting; layouts stay usable at accessibility sizes (capped where needed). At accessibility sizes nothing truncates: the tile grids become one column, form rows put the control under its label, and paired buttons stack.
- **Tasks:** [REF:task:2026-07-ux-improvement-backlog | ux-improvement-backlog], [REF:task:2026-10-accessibility-text-sizes | accessibility-text-sizes]
- **Acceptance:** `src/MainApp/UnitTests/FontCraftifyTests.swift::testCraftifyFontsUseTextStyles` | `src/Common/UnitTests/OperationGridLayoutTests.swift::testColumnCountDropsToOneAtAccessibilitySizes` | `deno task check`
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

- **Description:** The operations list in the app and the transformation picker in the share extension render every operation with one and the same tile — icon on the left, operation name, and the configured setting on a second line — laid out in the same two-column grid (one column at accessibility text sizes, see [REF:fr:ux.dynamic-type | FR-UX.DYNAMIC-TYPE]). The setting value goes through one shared localized formatter: summarize shows the localized label, never the canonical English string that goes into the prompt, and translate shows the bare language name. Whatever the user arranges in the app is what the extension shows.
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

### FR-UX.TRIM-EDGES: No stray whitespace around input and result [ANC:fr:ux.trim-edges]

- **Description:** Neither the text the user shares nor the text the model returns carries stray whitespace at its edges. The shared selection is trimmed before it reaches the prompt, so a trailing newline captured by the selection is never echoed back by the model; the model's answer is trimmed once, in one place for all four providers, before it becomes the displayed result and before it is copied to the clipboard. Line breaks inside the text — paragraphs, lists, code blocks — are left untouched.
- **Tasks:** [REF:task:2026-08-trim-whitespace-around-text | trim-whitespace-around-text]
- **Acceptance:** `src/ShareExtension/UnitTests/ShareExtensionManagerTests.swift::testProcess_TrimsWhitespaceAroundResult` | `deno task check`
- **Status:** [x]

### FR-UX.REVIEW-REQUEST: Ask for an App Store rating after the third success [ANC:fr:ux.review-request]

- **Description:** After the user's third successful text operation, Craftify asks the system to show Apple's App Store rating prompt — Apple's own sheet, no custom dialog and no "rate us" button anywhere. Successes are counted where the operations run, in the share extension, and kept in the App Group defaults together with the moment of the first counted success. The request itself is made by the app, never by the extension, and only at the end of a finished task: about 2 seconds after the user closes one of the app's task screens — the add-operation form, the edit-operation form or Settings. Opening the app or bringing it to the foreground never asks. Opening another task screen or leaving the foreground during those 2 seconds cancels the request. The rating is due only when all of these hold: at least 3 successes, no request yet in this marketing version (`CFBundleShortVersionString`), and today is not the calendar day of the first counted success. An install that already has successes but no recorded first day takes today as its first day the first time the app reads it. An error, a timeout or a cancelled operation never counts, and nothing is asked before consent (the home screen is not shown before it). After a request the app remembers the version and forgets the counter and the first day; successes made later in that version do not count, and a later version needs 3 new successes, again not on the day of the first of them. Apple's own cap of 3 prompts per 365 days applies on top.
- **Tasks:** [REF:task:2026-11-app-store-rating-request | app-store-rating-request]
- **Acceptance:** `src/Common/UnitTests/ReviewRequestPolicyTests.swift::testRequestsReviewOnThirdSuccessOncePerVersion` | `src/Common/UnitTests/ReviewRequestPolicyTests.swift::testNotDueOnTheDayOfTheFirstSuccess` | `src/Common/UnitTests/ReviewRequestPolicyTests.swift::testInstallWithCountButNoFirstDayIsNotAskedTheSameDay` | `src/MainApp/UnitTests/ReviewPromptTriggerTests.swift::testClosingATaskScreenStartsTheCountdown` | `src/MainApp/UnitTests/ReviewPromptTriggerTests.swift::testOpeningAnotherTaskScreenCancelsTheCountdown` | `src/MainApp/UnitTests/ReviewPromptTriggerTests.swift::testLeavingTheForegroundCancelsTheCountdown` | `src/ShareExtension/UnitTests/ShareExtensionViewModelTests.swift::testProcess_OnlySuccessCountsTowardReview` | `deno task check`
- **Status:** [x]

### FR-OP.FIND-ERRORS: Find errors without correcting them [ANC:fr:op.find-errors]

- **Description:** A "Find errors" operation, available in the add-operation list (not in the default set), checks shared text for spelling, grammar and punctuation errors (style and word choice are out of scope) and changes nothing. The result screen shows the original text exactly as shared, then a numbered list of the errors found; each entry gives the line and column where the erroneous fragment starts, the fragment itself and a description. The descriptions are written in the user's native language from Settings, like Explain; the line/column label and the "no errors" message are in the interface language. The model returns the errors as JSON with the fragment copied verbatim; Craftify finds each fragment in the original to compute its position, so positions do not depend on the model counting characters. A fragment that cannot be found is listed without a position. When the answer is not in that JSON shape (for example, after the user rewrote the prompt), the model's answer is shown as it is.
- **Tasks:** [REF:task:2026-11-find-errors-operation | find-errors-operation]
- **Acceptance:** `src/Common/UnitTests/FindErrorsReportTests.swift::testTextWithoutErrorsSaysSo` | `src/Common/UnitTests/FindErrorsReportTests.swift::testMultipleErrorsAreListedWithLineAndColumn` | `src/Common/UnitTests/FindErrorsReportTests.swift::testOriginalTextIsKeptVerbatim` | `src/Common/UnitTests/FindErrorsReportTests.swift::testAnswerOutsideTheFormatIsShownAsIs` | `deno task check`
- **Status:** [x]

### FR-UX.STREAMING: Answers appear while the model writes them [ANC:fr:ux.streaming]

- **Description:** Explain, Summarize and Simplify show the model's answer on the result screen as it arrives, for all four providers (OpenAI, Claude, Mistral, OpenRouter), instead of waiting for the whole answer. The progress overlay gives way to the result screen when the first piece of text arrives; the text then grows in place, at most about ten updates a second. While the answer is still arriving, Close cancels the request and Copy is unavailable. The 30-second processing limit applies only until the first piece arrives: an answer that is already being written is never cut off by it. Simplify, which used to copy its result silently, now shows it the same way and copies the finished text to the clipboard when the answer is complete; the result screen says so. Find errors is not streamed, because its report needs the whole answer. Translate and Correct still copy silently and close. A provider error that arrives in the middle of an answer is shown like any other provider error.
- **Tasks:** [REF:task:2026-11-streaming-results | streaming-results]
- **Acceptance:** `src/ShareExtension/UnitTests/LLMStreamParsingTests.swift::testOpenAIChunksYieldTextUntilDone` | `src/ShareExtension/UnitTests/LLMStreamParsingTests.swift::testClaudeDeltasYieldTextUntilStop` | `src/ShareExtension/UnitTests/LLMStreamParsingTests.swift::testErrorInsideTheStreamIsThrown` | `src/ShareExtension/UnitTests/LLMStreamingIntegrationTests.swift::test_openAI_stream_sendsStreamFlagAndJoinsChunks` | `src/ShareExtension/UnitTests/LLMStreamingIntegrationTests.swift::test_claude_stream_joinsTextDeltas` | `src/ShareExtension/UnitTests/LLMStreamingIntegrationTests.swift::test_stream_httpError_isMapped` | `src/ShareExtension/UnitTests/ShareExtensionViewModelTests.swift::testProcess_StreamedTextIsShownBeforeCompletion` | `src/ShareExtension/UnitTests/ShareExtensionViewModelTests.swift::testProcess_TimeoutDoesNotCutAStreamingAnswer` | `src/ShareExtension/UnitTests/ShareExtensionManagerTests.swift::testSimplifyShowsResultAndCopiesIt` | `src/ShareExtension/UnitTests/ProcessingManagerLLMIntegrationTests.swift::test_streamingOperation_reportsGrowingText` | `src/ShareExtension/UnitTests/ProcessingManagerLLMIntegrationTests.swift::test_findErrors_isNotStreamed` | `deno task check`
- **Status:** [x]


### FR-INPUT.PAGE-TEXT: A shared link sends the page's own text, not the site around it [ANC:fr:input.page-text]

- **Description:** When the user shares a link, the operation receives the text a reader of the page would read: the site's navigation, menus, table of contents, sidebars, form fields and buttons, site header and footer, scripts and styles are left out. A form itself is kept, because old sites wrap the whole article in one. The page is read in the character set its server or its `meta` tag declares (such as KOI8-R or Windows-1251), and as UTF-8 when neither declares one. When the page marks its main content (a `main` element or `role="main"`), only that block is used; otherwise the rest of the page is. A header inside the main content or inside an article — where the page title lives — is kept. A pop-up menu hidden behind a toggle button (`aria-haspopup`, such as Wikipedia's list of the article's languages) is left out together with its button, even inside the main content. A page made of nothing but navigation still yields its text rather than an empty-page error. Because a site can build its menus without such markup, the page text reaches the model wrapped in `<page url="…">`, and every operation that accepts a link tells the model to find the page's main content — the article or post with its title — work only on it, and never output the wrapper.
- **Tasks:** [REF:task:2026-11-page-main-text | page-main-text], [REF:task:2026-11-page-main-part-prompt | page-main-part-prompt], [REF:task:2026-11-page-text-forms-charset | page-text-forms-charset]
- **Acceptance:** `src/Common/UnitTests/SwiftSoupTextFetcherTests.swift::test_fetchText_takesTheMainBlockAndDropsSiteChrome` | `src/Common/UnitTests/SwiftSoupTextFetcherTests.swift::test_fetchText_withoutMainBlock_keepsTheArticleAndDropsNavigation` | `src/Common/UnitTests/SwiftSoupTextFetcherTests.swift::test_fetchText_dropsPopupMenusInsideTheMainBlock` | `src/Common/UnitTests/SwiftSoupTextFetcherTests.swift::test_fetchText_pageOfOnlyNavigation_fallsBackToTheWholeBody` | `src/Common/UnitTests/SwiftSoupTextFetcherTests.swift::test_fetchText_keepsAnArticleWrappedInAForm` | `src/Common/UnitTests/SwiftSoupTextFetcherTests.swift::test_fetchText_decodesThePageInTheCharsetTheServerDeclares` | `src/Common/UnitTests/SwiftSoupTextFetcherTests.swift::test_fetchText_decodesThePageInTheCharsetItsMetaDeclares` | `src/ShareExtension/UnitTests/ShareExtensionViewModelTests.swift::testProcess_PageTextIsMarkedAsAWebPage` | `src/Common/UnitTests/OperationPromptTemplateTests.swift::testURLOperationsAskForThePageMainContent` | `deno task check`
- **Status:** [x]
