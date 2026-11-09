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
rating when the threshold is reached (the moment changed the same day, see
"Revision: ask when a task screen closes" below). Reasons:

- A clipboard operation closes the extension in the same moment it succeeds, so
  there is no screen left to show a prompt on, and those are most operations.
- After a displayed result the user is still mid-task: they have to copy the
  text and go back to the app they shared from. A prompt there sits on top of
  that work.
- The extension runs inside another app's share sheet under its own bundle id,
  which is not the App Store product, and the API's behaviour there is
  undocumented. A later probe the same day settled it (see the revision below):
  the system cannot show the sheet from the extension at all.
- The app's home screen is a calm moment: nothing is in progress.

Cost of this choice: a user who only ever uses the share extension and never
reopens the app is never asked. Opening the app to change a tile or a model is
common enough that this is acceptable for a first version.

### Revision: ask when a task screen closes (2026-11-09)

The first version asked about 1.5 s after every return to the foreground. That
is the case Apple's StoreKit guidance names as the one to avoid: "Avoid showing
a request for a review immediately when a user launches your app, even if it
isn't the first time it launches". The same guidance says to ask "at the end of
a sequence of events that they successfully complete" and to avoid the first
launch and onboarding.

Asking in the extension, right after the operation succeeds, would match that
best, so it was probed on 2026-11-09. It cannot work: in the extension the
system's StoreKit UI service fails with `LSApplicationRecord` error -10814 and
"item ID is missing", because it looks up the extension's bundle id, which is
not an App Store item. The same build's main app shows the sheet. So the
request stays in the app.

Approved by the owner on 2026-11-09: ask about 2 s after the user closes one of
the app's task screens — the add-operation form, the edit-operation form or
Settings. Those are the ends of finished tasks in the app. The rules that
changed:

- No request on launch or on any return to the foreground.
- Closing a task screen starts a 2-second countdown. Opening another task
  screen or leaving the foreground cancels it; coming back does not resume it.
- The rating is due only when there are at least 3 successes, this version has
  not been asked, and today is not the calendar day of the first counted
  success ("not on the first day of use").
- The extension stores the moment of the first counted success
  (`CraftifyReviewFirstSuccessDate`) when it counts a success and the key is
  missing. An install that already has a count but no such key takes today as
  its first day the first time the app reads it, and stores it, so an update
  never prompts on the day it lands.
- A request clears the counter and the first day together, so a later version
  needs 3 new successes and, again, not on the day of the first of them.
- The decision is in two testable types: `ReviewRequestPolicy.reviewDecision()`
  (with an injected clock and calendar) and `ReviewPromptTrigger` (the countdown
  state, fed by `HomeView`'s sheets and the scene phase).

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
- [x] FR-UX.REVIEW-REQUEST: the rating is never due on the calendar day of the
      first counted success; an install with a count but no first day takes
      today as that day
  - Test: `src/Common/UnitTests/ReviewRequestPolicyTests.swift::testNotDueOnTheDayOfTheFirstSuccess`
  - Test: `src/Common/UnitTests/ReviewRequestPolicyTests.swift::testInstallWithCountButNoFirstDayIsNotAskedTheSameDay`
  - Test: `src/Common/UnitTests/ReviewRequestPolicyTests.swift::testNextVersionMeasuresItsFirstDayAnew`
  - Evidence: `deno task check`
- [x] FR-UX.REVIEW-REQUEST: only closing a task screen starts the countdown;
      opening another task screen or leaving the foreground cancels it, and
      launch or a return to the foreground never asks
  - Test: `src/MainApp/UnitTests/ReviewPromptTriggerTests.swift::testClosingATaskScreenStartsTheCountdown`
  - Test: `src/MainApp/UnitTests/ReviewPromptTriggerTests.swift::testOpeningAnotherTaskScreenCancelsTheCountdown`
  - Test: `src/MainApp/UnitTests/ReviewPromptTriggerTests.swift::testLeavingTheForegroundCancelsTheCountdown`
  - Test: `src/MainApp/UnitTests/ReviewPromptTriggerTests.swift::testNothingIsPendingAtLaunchOrOnReturnToForeground`
  - Evidence: `deno task check`
- [x] FR-UX.REVIEW-REQUEST: the sheet appears about 2 s after a task screen
      closes, in a Release build
  - Acceptance: manual — agent simulator walk 2026-11-09 (second walk), Release
    build, iPhone 17 Pro; see the second walk notes below

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

### Walk notes, second walk (2026-11-09, ask when a task screen closes)

Release build on the iPhone 17 Pro simulator, Craftify freshly installed,
consent given through "Set up later". State was seeded in the App Group
defaults with `simctl spawn <udid> defaults write <group plist> ...`
(`CraftifyReviewSuccessCount -int 3`, `CraftifyReviewFirstSuccessDate -date
...`), and the seeded keys were deleted afterwards. Log lines come from
`simctl spawn <udid> log show --info`, subsystem `Internal`, categories
`ReviewRequest` and `SettingsUI`.

- Count 3, first success today: Settings opened and closed, no sheet; about
  2 s later the log had `Review request: not asked ["reason":
  "first_day_of_use"]`.
- First success yesterday, app relaunched: no sheet 5 s after launch and no
  `ReviewRequest` line at all. Settings opened and closed (closed at
  20:43:58.504): the "Enjoying Craftify?" sheet appeared, the log had
  `Review request: asked the system for a rating` at 20:44:00.612, 2.1 s
  later. "Not Now" pressed; the defaults then held
  `CraftifyReviewRequestedVersion = "2.0.3"`, a counter of 0 and no first day.
- Same version, counter forced back to 3 with the first day yesterday:
  Settings opened and closed, no sheet; the log had `not asked ["reason":
  "already_asked_in_this_version"]`.
- Fresh cycle seeded again, the add-operation form opened from an empty cell
  and closed with Cancel: the sheet appeared, logged as asked at 20:45:04.507.
  "Not Now" pressed.
- Fresh cycle seeded again, Settings closed and Home pressed 0.7 s later: the
  log had `Review request: countdown cancelled`; back in the foreground there
  was no sheet and no request.

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
3. `RootView` takes the policy too. In the first version it ran a task keyed by
   `scenePhase` and asked shortly after every return to the foreground; the
   revision replaced that. Now `HomeView` reports whether any task sheet is
   open, `RootView` feeds that and the scene phase into `ReviewPromptTrigger`,
   and a task keyed by the trigger's countdown waits 2 s, then asks the
   trigger whether the countdown still holds and the policy whether the rating
   is due (`reviewDecision()`, which also applies the first-day rule) before
   calling `requestReview()` and `markReviewRequested()`.
4. Both sides log the decision at info level (subsystem `Internal`, categories
   `ShareExtension` and `ReviewRequest`) so it can be read with
   `log show --info`.
