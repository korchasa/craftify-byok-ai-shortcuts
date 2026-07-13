# Craftify — Project Rules

Craftify is a BYOK (bring-your-own-key) iOS app: users process selected text with their own LLM API key through a Share Extension. Targets: MainApp, ShareExtension, Common (shared sources compiled into each target). Tuist-generated project, SwiftUI + MVVM, 11 locales.

## Development Commands

- `./run check` — full verification: secret scan → generate (swiftgen + tuist) → fmt → lint (strict, warnings as errors) → periphery dead-code → build + tests on simulator → comment scan. The main acceptance gate for every change.
- `./run test` — build and run unit tests only.
- `./run generate` — regenerate Xcode project (Tuist) and localization enums (SwiftGen).
- Simulator UUID is env-overridable via `SIMULATOR_ID` / `TEST_SIMULATOR_ID`.

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
- **Verification Steps**: every plan includes specific verification commands (`./run check`, `tuist test`, manual simulator steps) — a plan without verification is a wish.
- **Functionality Preservation**: before refactoring, confirm `./run check` passes on the current state; run it again after edits.
- **Data-First**: when integrating provider APIs, inspect the actual wire format (SSE dialects, error bodies) before planning.
- **Architectural Validation**: for concurrency/streaming changes, sketch the event sequence first — races and cancellation leaks hide in prose.
- **Variant Analysis**: present alternatives as labeled options with Pros / Cons / Risks / Best-for; one option only when the path is obvious.
- **Plan Persistence**: after variant selection, save the detailed plan to `documents/tasks/<YYYY>/<MM>/<slug>.md` in GODS format.
- **Proactive Resolution**: exhaust codebase/docs/web before asking the user.

# YOU MUST

- Diagnose failures to root cause; after a second failed fix attempt, STOP and output a STOP-ANALYSIS REPORT (state, expected, 5-why chain, root cause, hypotheses) and wait for the user.
- When the root cause is outside your control (missing keys, unavailable services, signing configuration) — STOP and ask; do not invent workarounds.
- Keep `./run check` green: strict lint, periphery, and localization key parity across all 11 locales are part of the gate.
- Tests: fix the source, not the test; no stubs for internal code paths that can run for real.
