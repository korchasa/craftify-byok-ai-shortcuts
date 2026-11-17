---
date: 2026-11-17
status: done
implements:
  - FR-INPUT.PAGE-TEXT
related_tasks:
  - "[streaming-results](streaming-results.md)"
---
# Send the page's own text when a link is shared [ANC:task:2026-11-page-main-text]

## Goal

A shared link should be transformed as the article a reader sees, not as the website around it. Simplify on a Wikipedia link returned the site's menu and table of contents instead of a simpler article.

## Overview

### Context

- Found on 2026-11-17 during the simulator walk of streamed answers: Simplify on `https://en.wikipedia.org/wiki/Nocebo` answered with "Jump to content, Main menu, Move to sidebar, …, Log in" followed by the table of contents, in English, not simplified.
- Summarize hid the defect: it compresses the text and drops the noise on its own.

### Current State

- `SwiftSoupTextFetcher.fetchText` parsed the page and returned `body.text()` — every word on the page, menus, sidebars, table of contents and footer included.

### Constraints

- No new dependency: SwiftSoup is already linked.
- A page with no marked-up main content must still yield text, and a page made only of navigation must not become an "empty page" error.

## Definition of Done

- [x] FR-INPUT.PAGE-TEXT: a page with a `main` block yields that block's text without the site's menus, table of contents, sidebars and footer, keeping the page title
  - Test: `src/Common/UnitTests/SwiftSoupTextFetcherTests.swift::test_fetchText_takesTheMainBlockAndDropsSiteChrome`
  - Evidence: `deno task test CommonUnitTests/SwiftSoupTextFetcherTests`
- [x] FR-INPUT.PAGE-TEXT: without a `main` block the page loses its navigation, site header, forms and footer but keeps an article's own header
  - Test: `src/Common/UnitTests/SwiftSoupTextFetcherTests.swift::test_fetchText_withoutMainBlock_keepsTheArticleAndDropsNavigation`
  - Evidence: `deno task test CommonUnitTests/SwiftSoupTextFetcherTests`
- [x] FR-INPUT.PAGE-TEXT: a pop-up menu behind an `aria-haspopup` toggle is dropped even inside the main block
  - Test: `src/Common/UnitTests/SwiftSoupTextFetcherTests.swift::test_fetchText_dropsPopupMenusInsideTheMainBlock`
  - Evidence: `deno task test CommonUnitTests/SwiftSoupTextFetcherTests`
- [x] FR-INPUT.PAGE-TEXT: a page of nothing but navigation still yields its text
  - Test: `src/Common/UnitTests/SwiftSoupTextFetcherTests.swift::test_fetchText_pageOfOnlyNavigation_fallsBackToTheWholeBody`
  - Evidence: `deno task check`

## Solution

1. `PageMainText.text(of:)` (new, `src/Common/Sources/TextFetcher/PageMainText.swift`) works on the parsed body:
   - keeps the whole text aside as the fallback;
   - removes pop-up menus: the parent of every `aria-haspopup` toggle, unless that parent is the body, `main` or an article, in which case only the toggle goes;
   - removes `script`, `style`, `noscript`, `template`, `nav`, `aside`, `form`, the navigation, banner, footer, sidebar and search ARIA roles, and hidden elements;
   - removes `header` and `footer` that do not sit inside `main` or an `article`;
   - takes the longest `main` / `role="main"` block, or the body when there is none;
   - returns the whole text if nothing is left.
2. `SwiftSoupTextFetcher.fetchText` and the older `fetchAndExtractText` call it instead of `body.text()`.

## Verification notes

- RED first: the two structure tests failed with the whole page's text ("Jump to content Main menu … Privacy policy"), and the pop-up test with "Nocebo 34 languages Deutsch Français Edit links …".
- Simulator walk, iPhone 17, Debug build with the owner's OpenAI key, 2026-11-17: Simplify on the Nocebo link.
  - With only the structural rules the menu and table of contents were gone, but the article's language list and "Edit links" (a pop-up inside `main`) led the answer.
  - With the pop-up rule the answer opens with "Nocebo", the "From Wikipedia" line and the article's first paragraph, simplified.
- Known limit: the rules recognise semantic markup. A site that builds its menus from plain `div`s without ARIA roles still sends them; the model then sees them as before.
