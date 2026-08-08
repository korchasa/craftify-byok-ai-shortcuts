# Craftify — Project Rules

Craftify is a BYOK (bring-your-own-key) iOS app: users process selected text with their own LLM API key through a Share Extension. Targets: MainApp, ShareExtension, Common (shared sources compiled into each target). Tuist-generated project, SwiftUI + MVVM, 11 locales.

## Development Commands

- `deno task check` — full verification: task-script tooling (`deno fmt --check`, `deno lint`, `deno check`) → secret scan → generate (swiftgen + tuist) → fmt → lint (strict, warnings as errors) → periphery dead-code → build + tests on simulator → comment scan → a smoke run that installs and launches the app on the simulator. The main acceptance gate for every change. It **exits with a status**: the smoke run does not attach a log stream. For logs use `deno task dev` (build, install, launch and tail) or `deno task logs` against an already-running simulator.
- `deno task ci` — the same gate without the simulator smoke run. Prefer it when you only need a verdict and no simulator; this is also what GitHub Actions runs on every pull request and on `main`.
- `swiftlint lint --strict --quiet` — the lint step of the gate, runnable on its own in ~0.3 s. Run it after every source edit instead of learning about a style error six minutes into `deno task check`. The config is `opt_in_rules: all` minus a 130-line disable list, so the enabled set is invisible — you can only see what is *off*. Three rules cause most failures: every declaration under `src/**/Sources` needs an explicit access-level keyword (`explicit_acl`, hit in 5 of 19 recorded sessions), every `public` one needs a doc comment (`missing_docs`), and a `//` line between a doc comment and its declaration breaks both (`orphaned_doc_comment`) — put a `// [REF:fr:<id>]` marker inside the implementing function body, never above a documented declaration.
- `deno task test [test-id]` — build and run unit tests only: the whole `AllTests` suite with no argument, or one target/case (`deno task test MainAppUnitTests/TestExample`).
- `deno task generate` — regenerate Xcode project (Tuist) and localization enums (SwiftGen).
- Every command lives in `deno.json` and is implemented in `scripts/*.ts` — dependency-free TypeScript, type-checked and linted by the gate's own first step.
- Simulator UUID is env-overridable via `SIMULATOR_ID` / `TEST_SIMULATOR_ID`.
- A UITest that sets `XCUIDevice.shared.orientation` leaves the simulator in that orientation **between test runs** — the next portrait test fails spuriously ("not hittable", element frames report landscape-width coordinates like x≈710). Reset with `xcrun simctl shutdown <udid> && xcrun simctl boot <udid>` (boot is always portrait), or set `.portrait` in that test's `tearDown`.
- Right after edits, SourceKit often can't resolve same-module types/modules ("Cannot find type … in scope", "No such module 'XCTest'") — this is re-indexing noise, not a real error. The source of truth is `deno task check` / `tuist build`, not the live IDE diagnostics.
- **`tuist build` reads its own flags; it does not read what you pass through to xcodebuild.** Anything after `--` reaches xcodebuild, but Tuist decides where the products are by ITS own notion of configuration, platform and derived data. Three consequences, all of which cost a debugging session:
  - `-- -configuration Release` builds one thing and files it under `Debug-iphonesimulator`, with a green exit code. Use Tuist's `--configuration`, before `--`. (Broke `prod` until 2026-08-07: it could not find its own output.)
  - `-- -sdk iphoneos` produces a simulator build all the same. For a device SDK go through `tuist xcodebuild build`, where every xcodebuild flag is honoured. (Broke `size-report` for longer: it announced Release/iphoneos while measuring a debug simulator build against the 20 MB device ceiling.)
  - `--build-output-path` copies the products afterwards **out of Xcode's global derived data**, so combining it with `-- -derivedDataPath <dir>` fails with "The expected build products at … were not found". Pick one: either let Tuist copy (and accept the global cache), or point xcodebuild at your own derived data and read the app from `<dir>/Build/Products/<cfg>-iphonesimulator/`. (Hit on 2026-08-08 while making the smoke run share the test cache.)
  Verify all three by reading the "Copying build products to …" line and the path the app is actually installed from — never by the exit code.
- **The gate shares one derived-data directory (`DERIVED_DATA` in `scripts/config.ts`).** The test run, the smoke run and Periphery all use it: the smoke build stops recompiling what the tests just compiled, and Periphery scans their index instead of making its own clean build (51 s → 9 s). Periphery gets `--skip-build --index-store-path`, and `scripts/lint.ts` refuses a missing or stale index rather than silently scanning old code — compare against the newest file INSIDE the store, since a build never restamps the store directory itself.
- `tuist test` skips unchanged targets and reports "has no tests to run, finishing early" with exit code 0 — pass `--no-selective-testing` for an honest run. The gate itself already does (added 2026-08-02, after a green `check` was caught running no tests at all), so this bites only hand-rolled invocations. The **same message also appears when the class is not in the named scheme**, so pick the scheme first: unit tests live in `AllTests`, UI tests in the separate `UITests` scheme (`deno task check` runs only the unit ones). Subset run: `tuist test UITests --no-selective-testing --test-targets MainAppUITests/<Class>`. `xcodebuild -scheme AllTests` is not an option — it fails with "not currently configured for the test action".
- UI tests that look up **system** buttons by title (`Edit`, `Cancel`, `Delete`) must launch with `-AppleLanguages (en) -AppleLocale en_US` — the host simulator is not necessarily English. A test that must run in the default language matches by identifier or by structure instead (`app.navigationBars.firstMatch`, not `app.navigationBars["Model"]`). The default operation set is locale-dependent too (6 tiles in English, 7 in Russian), so never hard-code the tile count or an empty-slot index.
- Synthetic touches (`simctl`, `touch_path`) never start a UIKit drag session — the app sees nothing at all. Drag is only exercisable from XCUITest via `press(forDuration:thenDragTo:withVelocity:thenHoldForDuration:)`; hold at the end and take screenshots from outside the test to inspect the drag visually. Note that a drag is drawn **twice**: the lift snapshots the drag source view as-is, and only the moving copy comes from the `preview:` closure of `.onDrag(_:preview:)`. Anything the source view renders out of bounds ends up in the lift image.
- Tile identifiers are per operation **type** (`operation_row_translate` matches all three translate tiles), and in arrange mode every tile shares one accessibility label, so `element(boundBy:)` points at a different tile once a drag reorders the tree — address tiles by a type that occurs once (`explain`). Arrange mode also moves the frames: the wiggle tilt and the minus badge pushed past the corner widen a tile's frame by ~6 pt, and neighbours wiggle out of phase — compare coordinates with an 8–12 pt accuracy and find a row neighbour with a coarse Y tolerance (~20 pt), never with 1 pt.
- A gesture modifier that appears together with a state change (`.onDrag` added only in arrange mode) never picks up the touch already in progress — UIKit attaches the recognizer to a ready view. Attach drag unconditionally and drive the state from the lift closure instead.
- `deno task icons` — regenerate app icons. MainApp uses an **iOS 26 Icon Composer bundle** `src/MainApp/Resources/AppIcon.icon` (NOT an appiconset — that was removed; a duplicate `AppIcon` name breaks App Store ingest). It is deliberately flat: `"glass": false`, shadow/translucency zeroed. Per-appearance colour via `fill-specializations` (white "C" light / black "C" dark); the turquoise background fill MUST also carry a `dark` specialization or dark falls back to system gray. To change the letter, edit `documents/icon-glyph.svg` (transparent mask) then `deno task icons`. ShareExtension keeps its classic appiconset (fed by `documents/icon.svg`).
- Preview any icon appearance **offline without a build** via Apple's renderer: `"/Applications/Xcode.app/Contents/Applications/Icon Composer.app/Contents/Executables/ictool" AppIcon.icon --export-image --output-file out.png --platform iOS --rendition Dark --width 1024 --height 1024 --scale 1` (renditions: Default, Dark, TintedLight/Dark, ClearLight/Dark). When checking on the live springboard instead, the icon is cached: `simctl uninstall` + reboot before reinstall, or it shows the stale variant. Also: the home-screen **icon appearance mode** (Light/Dark/Auto, set in the wallpaper/Customize menu) is separate from the system dark theme — a dark icon variant only shows when that mode is Dark or Auto, so a dark-theme screenshot can still show the light icon.

## Documentation Hierarchy

1. **`AGENTS.md`** — this file: project vision, constraints, doc role bindings. READ-ONLY reference.
2. **SRS** (`documents/srs.md`) — "What" & "Why". Source of truth for functional requirements (FR-*). Created on first FR commit.
3. **SDS** (`documents/architecture.md`) — "How". Existing architecture document plays the SDS role.
4. **Tasks** (`documents/tasks/<YYYY>/<MM>/<slug>.md`) — persistent committed plans/records per task, GODS format (see below).
5. **Index** (`documents/index.md`) — agent-maintained navigation aggregator (FR rows in SALP form). Created on first write.

## Interconnectedness (SALP)

Cross-references between docs and from code to docs use SALP grammar:

- Anchor: `[ANC:<ns>:<id>]` on the heading line it labels, e.g. `### FR-UX.STREAMING: ... [ANC:fr:ux.streaming]`.
- Reference: `[REF:<ns>:<id>]` or `[REF:<ns>:<id> | <display>]`.
- Namespaces in use: `fr`, `task`, `sds`. ID grammar: lower-kebab, periods preserved for hierarchical IDs (`FR-UX.STREAMING` → `ux.streaming`).
- In Swift code: `// [REF:fr:<id>]` comment next to implementing logic.

### Tasks format

- One file per task: `documents/tasks/<YYYY>/<MM>/<slug>.md` (kebab-case slug, max 40 chars). Never reuse another session's file.
- Frontmatter (all keys required, in order): `date` (quoted ISO), `status: to do | in progress | done | superseded`, `implements: [FR-...]`, `tags: [...]`, `related_tasks: [...]`.
- Status auto-derives from `## Definition of Done` checkboxes on commit; do not edit manually mid-flight.

### GODS Format

```markdown
---
date: "YYYY-MM-DD"
status: to do
implements: [FR-XXX]
tags: []
related_tasks: []
---
# [Task Title]

## Goal

[Why? Business value.]

## Overview

### Context

[Problematics, pain points, constraints, refs to relevant files/docs.]

### Current State

[Technical description of existing code relevant to the task.]

### Constraints

[Hard limits, anti-patterns, requirements.]

## Definition of Done

Every DoD item MUST pair with (a) an FR-ID and (b) a runnable acceptance reference.

- [ ] FR-XXX: <observable behavior>
  - Test: `<path/to/test>::<test_name>`
  - Evidence: `<command that passes iff the item is done>`

## Solution

[Detailed step-by-step for the SELECTED variant only. Filled AFTER user selects a variant.]
```

## Planning Rules

- **Environment Side-Effects**: changes touching App Store metadata, entitlements, App Group storage schema, or privacy policy text must include the migration/publishing step — otherwise it works locally and breaks in review or on user devices.
- **Verification Steps**: every plan includes specific verification commands (`deno task check`, `tuist test`, manual simulator steps) — a plan without verification is a wish.
- **Functionality Preservation**: before refactoring, confirm `deno task check` passes on the current state; run it again after edits.
- **Data-First**: when integrating provider APIs, inspect the actual wire format (SSE dialects, error bodies) before planning.
- **Architectural Validation**: for concurrency/streaming changes, sketch the event sequence first — races and cancellation leaks hide in prose.
- **Variant Analysis**: present alternatives as labeled options with Pros / Cons / Risks / Best-for; one option only when the path is obvious.
- **Plan Persistence**: after variant selection, save the detailed plan to `documents/tasks/<YYYY>/<MM>/<slug>.md` in GODS format.
- **Proactive Resolution**: exhaust codebase/docs/web before asking the user.

# YOU MUST

- Diagnose failures to root cause; after a second failed fix attempt, STOP and output a STOP-ANALYSIS REPORT (state, expected, 5-why chain, root cause, hypotheses) and wait for the user.
- When the root cause is outside your control (missing keys, unavailable services, signing configuration) — STOP and ask; do not invent workarounds.
- Keep `deno task check` green: strict lint, periphery, and localization key parity across all 11 locales are part of the gate.
- A visual defect is only fixed once you have **seen** the fixed state — a screenshot, a rendered frame, a captured video. Reasoning from the code is a hypothesis, not evidence. If you cannot observe it, say the fix is unverified and name what you would need to verify it; never phrase an unobserved conclusion as an accomplished fact.
- Tests: fix the source, not the test; no stubs for internal code paths that can run for real.
