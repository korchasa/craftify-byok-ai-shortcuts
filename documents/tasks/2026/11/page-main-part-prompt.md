---
date: 2026-11-17
status: done
implements:
  - FR-INPUT.PAGE-TEXT
related_tasks:
  - "[page-main-text](page-main-text.md)"
---
# Ask the model to pick out the page's main content [ANC:task:2026-11-page-main-part-prompt]

## Goal

Keep a shared link's menus out of the answer on sites whose markup the extraction cannot read.

## Overview

### Context

- `PageMainText` cleans a page by its semantic markup (`main`, `nav`, ARIA roles). A site that builds its menus from plain `div`s still sends them to the model.
- The owner chose (2026-11-17) to ask the model to pick out the main part of the page, not only to ignore headers and footers.

### Current State

- The model receives the page text inside `<input>` exactly like typed text, so it cannot tell that the text came from a web page.
- Only Summarize and Simplify accept a link (`supportsURL`).

### Constraints

- The marker must be added where the share sheet knows the input is a link: `ShareExtensionViewModel.performWork`.
- A custom system prompt replaces the default one, so it does not carry the new rule.

## Definition of Done

- [x] FR-INPUT.PAGE-TEXT: page text reaches the model as `<page url="…">…</page>`
  - Test: `src/ShareExtension/UnitTests/ShareExtensionViewModelTests.swift::testProcess_PageTextIsMarkedAsAWebPage`
  - Evidence: `deno task test ShareExtensionUnitTests/ShareExtensionViewModelTests`
- [x] FR-INPUT.PAGE-TEXT: every operation that accepts a link asks the model to pick out the page's main content
  - Test: `src/Common/UnitTests/OperationPromptTemplateTests.swift::testURLOperationsAskForThePageMainContent`
  - Evidence: `deno task check`

## Solution

1. `WebPageInput` (new, `src/Common/Sources/WebPageInput.swift`): `wrap(_:url:)` and the shared `promptRule`.
2. The Summarize and Simplify default prompts carry `promptRule` in their rules.
3. `ShareExtensionViewModel.performWork` wraps the resolved text when the input is a link.
4. Simulator walk: Simplify and Summarize on a live page with the owner's key; the answer starts with the article and carries no `<page>` tags.

## Verification notes

- RED first: the view-model test received the bare "Nocebo article", the prompt test found the rule missing in both the Summarize and the Simplify prompt.
- `deno task check`, 2026-11-17: 278 tests green, SwiftLint strict clean.
- Simulator walk, iPhone 17, Debug build with the owner's OpenAI key, 2026-11-17: Simplify on `https://en.wikipedia.org/wiki/Nocebo` streamed an answer that opens with the title "Nocebo", ends with the Ethics section's last paragraph, and carries no `<page>` tags, menus or references; the "copied" note appeared.
- Not checked: a site whose menus have no semantic markup, the case this rule exists for; and Summarize live after this change.
