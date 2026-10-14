---
date: "2026-10-14"
status: in progress
implements: [FR-UX.DYNAMIC-TYPE]
tags: [accessibility, dynamic-type, layout, ipad, dark-mode]
related_tasks: []
---

# Keep every label readable at accessibility text sizes [ANC:task:2026-10-accessibility-text-sizes]

## Goal

A user who reads with large text must be able to tell the operations and the
buttons apart. At the largest sizes the app cut labels down to their first
letters, so "Cancel" and "Save" both read "…", and an operation was picked by
its colour alone.

## Overview

### Context

Found on 2026-10-14 during the pre-release simulator walk of 2.0.3 (Release
build, iOS 26.5, `xcrun simctl ui <udid> content_size accessibility-extra-large`).
None of it came from 2.0.3 — no view code changed since 2.0.2.

- Home tiles truncated to "Ex…", "Tr…", "Co…"; extension tiles to "S…"/"Si…"
  on iPhone and "Summ…" in the iPad popover.
- The add-operation sheet's buttons truncated to "Ca…" and "Sa…".
- "OpenAI" and "English" hyphenated mid-word next to their row labels.
- The consent screen scrolled its text under the status bar.
- On iPad in dark mode, black bands showed on both sides of the content column
  (at every text size, not only the large ones).

Apple's guidance for Dynamic Type: avoid truncation, and at accessibility sizes
stack horizontally arranged items vertically.

### Current State

- `OperationTileView` set `lineLimit(1)` on the title and the setting, and both
  grids used a fixed `OperationTileConstants.columns = 2`.
- Form rows (`AddOperationView`, `EditOperationView`, `SettingsView`,
  `HowToUseView`) were `HStack { label; Spacer(); control }`, and
  `CraftifyButtonBar` was a plain `HStack`.
- `RootView` capped the content at 700 pt with no background outside it, so the
  window's own background (black in dark mode) showed beside the `#17171c` column.
- `HowToUseView` has no navigation bar, and its `ScrollView` scrolled under the
  transparent status bar.

### Constraints

- Default-size appearance must not change.
- Follow the platform pattern instead of inventing one: switch layouts on
  `DynamicTypeSize.isAccessibilitySize`, no per-screen font caps.
- The share extension keeps its existing cap at `.accessibility3`.

## Definition of Done

- [x] FR-UX.DYNAMIC-TYPE: the tile grid has one column at accessibility sizes and two otherwise
  - Test: `src/Common/UnitTests/OperationGridLayoutTests.swift::testColumnCountDropsToOneAtAccessibilitySizes`
  - Test: `src/Common/UnitTests/OperationGridLayoutTests.swift::testSingleColumnCellSpansTheContainer`
  - Evidence: `deno task check`
- [x] FR-UX.DYNAMIC-TYPE: every label in the app and the extension reads in full at
      `accessibility-extra-large` on iPhone 17 Pro and iPad Pro 13", light and dark
  - Acceptance: manual — agent simulator walk 2026-10-14 — consent, home, settings,
    add, edit and the extension, screenshotted per device and appearance
- [x] FR-UX.DYNAMIC-TYPE: default-size screens are unchanged
  - Acceptance: manual — pixel diff of the 2.0.3 Release build against this one at
    the default size, status bar cropped: consent, home, settings and add sheet on
    iPhone in light and dark, consent and home on iPad in light — 0 differing pixels.
    In iPad dark mode the only difference is the side margins (the band fix).
- [ ] FR-UX.DYNAMIC-TYPE: the extension's result screen stacks "Close" and
      "Copy & Close" at accessibility sizes
  - Acceptance: manual — not walked: reaching the result needs a live provider key.
    Same `AdaptiveStack` as the form button bar, which was walked.

## Solution

1. `OperationGridLayout.columnCount(for:)` returns 1 at accessibility sizes;
   `HomeView` and `ShareExtensionView` read `dynamicTypeSize` and pass the count
   to `columns(count:)`, `cellWidth(…columnCount:)`, `displayOrder` and
   `withoutEmptyRows`. Tile labels may wrap to two lines instead of truncating.
2. `AdaptiveStack` (Common): an `HStackLayout` normally, a leading
   `VStackLayout` at accessibility sizes. Used by `CraftifyButtonBar`, the
   extension's button row and the API-key rows in Settings.
3. `FormRow` (MainApp): label and control side by side, or the control under the
   label at full width. Replaces every `HStack { label; Spacer(); control }` row;
   the controls lose their own `.frame(maxWidth: .infinity, alignment: .trailing)`,
   which now lives in `FormRow`.
4. The add sheet opens at `.large` on iPhone at accessibility sizes too: with the
   buttons stacked, the half-height detent left room for one row of the form.
5. The home list starts scrolled to the bottom (`defaultScrollAnchor(.bottom)`,
   iOS 17+), so the bottom tiles stay under the thumb when one column overflows.
6. `RootView` fills the area outside the 700 pt column with the palette
   background; `HowToUseView` puts a zero-height top inset with the background
   behind the status bar.
