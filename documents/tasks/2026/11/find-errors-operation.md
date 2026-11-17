---
date: "2026-11-17"
status: done
implements: [FR-OP.FIND-ERRORS]
tags: [operations, l10n]
related_tasks: []
---

# Find errors without correcting them [ANC:task:2026-11-find-errors-operation]

## Goal

Let a user see what is wrong in a text and decide how to fix it, instead of getting a silently corrected copy. Requested in GitHub issue #12.

## Overview

### Context

Issue #12 asks for an operation that returns the original text unchanged followed by an enumerated list of detected errors (description plus position), with localizable messages, detection only, and unit tests for a clean text and a text with several errors. The owner told the session to fix every open Craftify item on 2026-11-17.

### Current State

Five operations exist (`OperationKind`), each an `OperationType` whose prompt goes to the model and whose answer is shown or copied as it comes. Correct already fixes errors, but returns only the corrected text. Nothing post-processes a model answer.

### Constraints

- Language models count characters badly, so positions must not come from the model.
- The result view renders inline Markdown only, so the original must be escaped to stay verbatim.
- Common code compiles into both targets: every new string goes into both string tables, 11 locales each.
- The new kind stays out of the default operation set, so existing grids and the locale-dependent default tests do not change.

## Definition of Done

- [x] FR-OP.FIND-ERRORS: a clean text yields the original plus a "no errors" line
  - Test: `src/Common/UnitTests/FindErrorsReportTests.swift::testTextWithoutErrorsSaysSo`
  - Evidence: `deno task test CommonUnitTests/FindErrorsReportTests`
- [x] FR-OP.FIND-ERRORS: several errors are numbered with line, column, fragment and description
  - Test: `src/Common/UnitTests/FindErrorsReportTests.swift::testMultipleErrorsAreListedWithLineAndColumn`
  - Evidence: `deno task test CommonUnitTests/FindErrorsReportTests`
- [x] FR-OP.FIND-ERRORS: the original text survives Markdown rendering unchanged
  - Test: `src/Common/UnitTests/FindErrorsReportTests.swift::testOriginalTextIsKeptVerbatim`
  - Evidence: `deno task test CommonUnitTests/FindErrorsReportTests`
- [x] FR-OP.FIND-ERRORS: an answer outside the JSON shape is shown as it is
  - Test: `src/Common/UnitTests/FindErrorsReportTests.swift::testAnswerOutsideTheFormatIsShownAsIs`
  - Evidence: `deno task check`

## Solution

1. `OperationKind.findErrors` (`find_errors`, symbol `text.magnifyingglass`) and `FindErrorsOperation`: display mode, prompt asks for `{"errors":[{"fragment","description"}]}` with descriptions in the native language and fragments copied verbatim.
2. `OperationType.presentResult(_:sourceText:)`, identity by default; `ProcessingManager` applies it to every answer.
3. `FindErrorsReport.render(modelOutput:sourceText:)`: strip code fences, decode, locate each fragment from the end of the previous match (falling back to the start), build escaped original + localized list.
4. Wire the kind into every switch (factory, display, add/edit views, edit view model), add the label and the three report strings to both tables in 11 locales.
5. Live check against OpenAI with the owner's test key; simulator check of the add flow.

## Verification notes

- Live check, `gpt-5.6-luna`, 2026-11-17: a Russian text with four misspellings over two lines returned four fragments with Russian descriptions; an English text returned three (including the two-word fragment "they has"); a correct sentence returned `{"errors":[]}`. Every answer was bare JSON, as the prompt asks.
- Simulator, iPhone 17, Russian UI: "Найти ошибки" is the last entry of the add-operation type picker and saves as a tile with the magnifier symbol.
- Not checked on screen: the Share Extension result sheet with a real answer. Its rendering path is the same inline-Markdown parser that `testOriginalTextIsKeptVerbatim` runs.
