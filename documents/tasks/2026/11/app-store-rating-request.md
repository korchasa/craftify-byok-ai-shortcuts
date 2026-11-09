---
date: "2026-11-09"
status: done
implements: [FR-UX.REVIEW-REQUEST]
tags: [store, rating, storekit, app-group]
related_tasks: []
---

# Ask for an App Store rating after the third success [ANC:task:2026-11-app-store-rating-request]

## Goal

Craftify is live in the App Store with almost no ratings, and a listing without
ratings converts worse. Apple's own rating prompt is the one way to ask that
Apple allows and that costs the user one tap. Asking at the right moment — after
the app has already helped three times — gets ratings from people who got value,
and never nags anyone who did not. Approved by the owner on 2026-11-09.

## Overview

### Context

- Apple's API: `@Environment(\.requestReview)` (`RequestReviewAction`, SwiftUI,
  iOS 16+) and `AppStore.requestReview(in:)` (iOS 16+); the older
  `SKStoreReviewController.requestReview(in:)` is deprecated since iOS 18. The
  system decides whether to show anything and caps the prompt at 3 times in 365
  days per user; in a development build the sheet always shows, in TestFlight it
  never does.
- The app targets iOS 16.0, so `@Environment(\.requestReview)` is available
  without an availability check.

### Current State

- Every text operation runs in the share extension
  (`ShareExtensionViewModel.handleResult`). A success either closes the
  extension at once (clipboard operations: translate, correct, simplify) or
  shows the result with "Close" / "Copy & Close" (explain, summarize).
- The app itself runs no operation: it holds the onboarding, the tile grid and
  Settings. Both sides share the App Group `UserDefaults` suite
  (`AppGroup.identifier`).

### Where the request is made — extension or app

Checked in the iOS 27.2 SDK on 2026-11-09:

- `SKStoreReviewController.h` carries no `NS_EXTENSION_UNAVAILABLE` or
  `API_UNAVAILABLE(ios_app_extension)`; `RequestReviewAction` in
  `_StoreKit_SwiftUI.swiftinterface` and `AppStore.requestReview(in:)` in
  `StoreKit.swiftinterface` carry no `iOSApplicationExtension, unavailable`
  either. So the call compiles in an extension.
- Apple's documentation for all three describes the call for "your app" and
  says nothing about extensions, so what happens in one is undocumented.

Chosen: **count in the extension, ask in the app.** The extension increments
the counter in the App Group defaults after each success; the app asks for the
rating when it comes to the foreground on the home screen and the threshold is
reached. Reasons:

- A clipboard operation closes the extension in the same moment it succeeds, so
  there is no screen left to show a prompt on, and those are most operations.
- After a displayed result the user is still mid-task: they have to copy the
  text and go back to the app they shared from. A prompt there sits on top of
  that work.
- The extension runs inside another app's share sheet under its own bundle id,
  which is not the App Store product, and the API's behaviour there is
  undocumented and cannot be checked in the simulator without a live key.
- The app's home screen is a calm moment: nothing is in progress.

Cost of this choice: a user who only ever uses the share extension and never
reopens the app is never asked. Opening the app to change a tile or a model is
common enough that this is acceptable for a first version.

### Constraints

- Never at first launch, never after an error, a timeout or a cancelled
  operation, never in the middle of a task.
- At most one request per marketing version (`CFBundleShortVersionString`);
  a later version needs 3 new successes made in that version.
- No custom dialog, no "rate us" button or any other prompt.
- The counting logic is a small type with no UI, covered by unit tests.

## Definition of Done

- [x] FR-UX.REVIEW-REQUEST: the third success in a version makes the rating due,
      once per version; a later version needs 3 new successes
  - Test: `src/Common/UnitTests/ReviewRequestPolicyTests.swift::testRequestsReviewOnThirdSuccessOncePerVersion`
  - Test: `src/Common/UnitTests/ReviewRequestPolicyTests.swift::testLaterVersionNeedsThreeNewSuccesses`
  - Evidence: `deno task check`
- [x] FR-UX.REVIEW-REQUEST: only a successful operation counts; an error does not
  - Test: `src/ShareExtension/UnitTests/ShareExtensionViewModelTests.swift::testProcess_OnlySuccessCountsTowardReview`
  - Evidence: `deno task check`
- [x] FR-UX.REVIEW-REQUEST: the app shows the system rating sheet on the home
      screen once the counter reaches 3, and not before
  - Acceptance: manual — agent simulator walk 2026-11-09, Release build, iPhone 17
    Pro (iOS 27.2); see the walk notes below

### Walk notes (2026-11-09)

No provider key is part of the repository's test setup, so no operation could
succeed for real in the simulator. The successes were stood in for by writing
the counter into the App Group defaults
(`simctl spawn <udid> defaults write <group plist> CraftifyReviewSuccessCount -int N`)
and bringing the app back to the foreground; the extension's own counting is
covered by `testProcess_OnlySuccessCountsTowardReview`.

- A failed operation (shared `https://example.com` from Safari, Summarize, no
  key configured → "No API key configured") left the counter unset, and the app
  brought to the foreground afterwards showed no prompt.
- Counter 1 and counter 2: home screen, no prompt.
- Counter 3: the system "Enjoying Craftify?" sheet appeared over the home screen
  about a second after it showed; afterwards the defaults held
  `CraftifyReviewRequestedVersion = "2.0.3"` and a counter of 0, and
  `log show --info` had "Review request: asked the system for a rating".
- Counter forced back to 3 in the same version: no second prompt.

## Solution

1. `ReviewRequestPolicy` (Common): reads and writes two keys in the App Group
   defaults — `CraftifyReviewSuccessCount` and `CraftifyReviewRequestedVersion`.
   `recordSuccess()` increments the count unless the rating was already
   requested in this version; `shouldRequestReview()` is true when the count is
   at least `successThreshold` (3) and the stored version differs from the
   current one; `markReviewRequested()` stores the current version and resets
   the count. The version comes from `CFBundleShortVersionString` of the running
   bundle; the extension and the app share `MARKETING_VERSION`, so both read the
   same value.
2. `ShareExtensionViewModel` takes the policy in its initializer and calls
   `recordSuccess()` only in the success branch of `handleResult`, for both
   result modes. Errors, the timeout and `cancel()` never reach that branch.
3. `RootView` takes the policy too. On the home branch it runs a task keyed by
   `scenePhase`: when the scene is active it waits a short moment so the home
   screen is on screen first, and if the policy says the rating is due it calls
   `requestReview()` and `markReviewRequested()`. Leaving the foreground
   cancels the wait.
4. Both sides log the decision at info level (subsystem `Internal`, categories
   `ShareExtension` and `ReviewRequest`) so it can be read with
   `log show --info`.
