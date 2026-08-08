---
date: "2026-08-08"
status: done
implements: [FR-UX.TRIM-EDGES]
tags: [share-extension, clipboard, prompt]
related_tasks: []
---

# Strip stray whitespace around the input and the result

## Goal

A pasted result should look exactly like text the user typed. Today it arrives
with an extra line break at the end, so every paste needs a manual cleanup —
small, constant friction on the app's single most-used action.

## Overview

### Context

Reported from real use: pasting the result of an operation inserts one extra
newline at the end.

### Current State

The model's answer travelled from the provider to the pasteboard untouched.
`OpenAIAPIClient`, `ClaudeAPIClient`, `MistralAPIClient` and
`OpenRouterAPIClient` each returned the `content` field verbatim,
`ProcessingManager.processAsync` passed it through, and
`ShareExtensionManager.process` stored it in `lastResult` and handed it to
`ClipboardManager`. A grep for `trimmingCharacters` over `src` found fourteen
call sites — API key, operation prompt, model search, robots.txt — and none on
the result.

Models end an answer with a newline regardless of the prompt: every operation
already asks for the bare result (`TranslateOperation.defaultSystemPrompt`:
"Return only the translated text: no preamble, no notes"), and the newline still
comes back. It has to be removed on our side.

The input was not trimmed either. `ShareExtensionViewController.loadInputText`
takes the system string as-is, and it is interpolated between `<input>` and
`</input>` in every operation's `userContent`. A selection that grabbed a
trailing newline puts a blank line before the closing tag, which the model
happily reproduces — a second, indirect source of the same defect.

### Constraints

- Only the edges. Line breaks inside the text are formatting — paragraphs,
  lists, code blocks — and must survive untouched.
- One place for all four providers, not a fix repeated per client.

## Definition of Done

- [x] FR-UX.TRIM-EDGES: the result reaches the clipboard and the result screen
      without leading or trailing whitespace, with inner line breaks intact
  - Test: `src/ShareExtension/UnitTests/ShareExtensionManagerTests.swift::testProcess_TrimsWhitespaceAroundResult`
  - Test: `src/ShareExtension/UnitTests/ShareExtensionManagerTests.swift::testProcess_KeepsLineBreaksInsideResult`
  - Evidence: `deno task check`
- [x] FR-UX.TRIM-EDGES: the shared selection is trimmed before it reaches the prompt
  - Test: `src/ShareExtension/UnitTests/ShareExtensionViewModelTests.swift::testUpdateInputText_TrimsWhitespaceAroundInput`
  - Evidence: `deno task check`

## Solution

1. `ShareExtensionManager.process` trims the processed text once, right after
   the cancellation check, into `cleanResult`. That single value feeds
   `lastResult` (the display mode) and both clipboard branches, so display and
   copy can never disagree.
2. `ShareExtensionViewModel.truncated` became `normalizedInput`: it truncates to
   `maxInputTextLength` first and trims the edges after, so a cut long text does
   not end on a stray space. Both call sites — the initializer and
   `updateInputText` — go through it.

## Verification

`deno task test` alone is not enough here: it runs `tuist test` without building
the `ShareExtension` target first, and the run dies with "unable to resolve
module dependency: 'ShareExtension'" while reporting zero executed tests. The
build-then-test path used by `check`/`ci` (`buildAndTest`) is the one that works.

- Red: with both source files reverted to their previous state, exactly the three
  new tests fail and the other 219 pass.
- Green: with the fix in place, 222 of 222 pass.
