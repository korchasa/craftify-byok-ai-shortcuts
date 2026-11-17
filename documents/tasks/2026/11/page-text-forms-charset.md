---
date: 2026-11-18
status: done
implements:
  - FR-INPUT.PAGE-TEXT
related_tasks:
  - "[page-main-text](page-main-text.md)"
  - "[page-main-part-prompt](page-main-part-prompt.md)"
---
# Keep articles wrapped in a form, and read pages in their declared charset [ANC:task:2026-11-page-text-forms-charset]

## Goal

A shared link from an older site — one that wraps its article in a form or serves a non-UTF-8 page — must reach the model as the article, not as an error or the site's footer.

## Overview

### Context

- Found on 2026-11-18 while checking FR-INPUT.PAGE-TEXT on a site with menus built without semantic markup. OpenNet (`https://www.opennet.ru/opennews/art.shtml?num=60000`) was chosen for that.
- Summarize on that link answered "Нет текста для обработки": the server sends `Content-Type: text/html; charset=koi8-r`, and the fetcher decoded every page as UTF-8, so decoding failed before parsing.
- A probe of `PageMainText` on the real page (SwiftSoup from the build's package checkout, page decoded as KOI8-R) showed a second defect, introduced by [page-main-text](page-main-text.md): the article and its comments sit inside a moderation `<form>`, and dropping every `form` left 242 of 30,902 characters — ads and the footer, no article.

### Current State

- `SwiftSoupTextFetcher` decoded with `String(data:encoding: .utf8)` in both `fetchText` and `fetchAndExtractText`.
- `PageMainText.chromeSelector` listed `form`.

### Constraints

- Pages that declare no charset keep the old behaviour (UTF-8).
- No new dependency.

## Definition of Done

- [x] FR-INPUT.PAGE-TEXT: an article wrapped in a form is kept; only the form's fields and buttons are dropped
  - Test: `src/Common/UnitTests/SwiftSoupTextFetcherTests.swift::test_fetchText_keepsAnArticleWrappedInAForm`
  - Evidence: `deno task test CommonUnitTests/SwiftSoupTextFetcherTests`
- [x] FR-INPUT.PAGE-TEXT: a page is decoded in the charset from the `Content-Type` header
  - Test: `src/Common/UnitTests/SwiftSoupTextFetcherTests.swift::test_fetchText_decodesThePageInTheCharsetTheServerDeclares`
  - Evidence: `deno task test CommonUnitTests/SwiftSoupTextFetcherTests`
- [x] FR-INPUT.PAGE-TEXT: a page is decoded in the charset from its `meta` tag when the server declares none
  - Test: `src/Common/UnitTests/SwiftSoupTextFetcherTests.swift::test_fetchText_decodesThePageInTheCharsetItsMetaDeclares`
  - Evidence: `deno task check`

## Solution

1. `PageMainText.chromeSelector`: `form` is replaced by its controls — `input`, `select`, `textarea`, `button`, `label`. The test without a main block now uses a realistic subscribe form (label, input, button) instead of a form holding one bare word.
2. `HTMLDecoding.decode(_:declaredCharset:)` (new, `src/Common/Sources/TextFetcher/HTMLDecoding.swift`): the charset from the response (`URLResponse.textEncodingName`), else from a `meta` tag in the first 1024 bytes, mapped through `CFStringConvertIANACharSetNameToEncoding`; UTF-8 when neither is present or the name is unknown.
3. `SwiftSoupTextFetcher.fetchText` and `fetchAndExtractText` decode through it.

## Verification notes

- RED first: both charset tests failed with `noData`, the form test with `"News Forum Tags"` (the article gone).
- Probe on the real OpenNet page after the fix: 28,807 of 30,902 characters, article included; the unmarked menus and the comments remain for the model's main-content rule.
- `deno task check`: 281 tests passed, 0 failed.
- Simulator walk, iPhone 17, Debug build with the owner's OpenAI key, 2026-11-18:
  - Summarize on the Wikipedia Nocebo link (the prompt rule's first live run for Summarize): a Russian summary of the article from the definition to the ethics paragraph, no menus, no `<page>` tags.
  - Summarize on the OpenNet link before the fix: "Нет текста для обработки". After the fix: a summary of the article from its date and authors to its last paragraph (Zenbleed), with no menu, footer or reader comments.
- Seen, not changed: the robots.txt check requests `robots.txt` next to the page (`/opennews/robots.txt`, 404) instead of at the site root, so a site's real rules are never applied.
