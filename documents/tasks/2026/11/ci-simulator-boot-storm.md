---
date: "2026-11-18"
status: done
implements: []
tags: [ci, tests, simulator]
related_tasks: []
---
# CI stops being cancelled while the unit tests run [ANC:task:2026-11-ci-simulator-boot-storm]

## Goal

A push to `main` gets a verdict from CI — pass or fail — instead of a run that GitHub silently cancels and someone has to re-run by hand. On 2026-11-17 and 2026-11-18 two of six runs ended as `cancelled`, each costing a re-run and a manual look at the log.

## Overview

### Context

- The `Checks` job (`.github/workflows/ci.yml`, runner `macos-26`: Apple M1 virtual machine, 3 cores, 7 GB, no swap) runs `deno task ci`, which ran the unit tests through `scripts/tests.ts` with `-parallel-testing-enabled YES`.
- Cancelled runs 44304693733 (attempt 1) and 44134878986 (attempt 1) went silent after the last MainApp test (`FontCraftifyTests`) and were cancelled 14 min later with a bare "The operation was canceled." Neither the job timeout (60 min), the concurrency group (no newer run, no concurrency notice), a watchdog in the scripts (none exists), nor a person (the owner did not cancel; no agent transcript or shell history holds a cancel) did it.
- Every test had already reported in both cancelled runs (279/279 and 268/268). The silence after the last test exists in every run, passing ones too: 27 s to 7 min 45 s.
- A sampled diagnostic run (branch `diag/ci-test-hang`, run 44313753659) showed the cause: as soon as testing starts, the load average jumps from about 20 to 500–645 and free memory falls from 77% to 26%. The busy processes are the iOS userland of a freshly created simulator clone booting for the first time (widgets, lock-screen posters, Photos, Health, sync daemons). The 30 s sampler itself could not run for 5.5 min. GitHub staff describe a bare "The operation was canceled." as the symptom of a runner starved of CPU and disk ([actions/runner-images#11858](https://github.com/actions/runner-images/issues/11858)): the runner cannot renew its job lease, and the server cancels the job.

### Current State

Measured test phase and peak load on the same runner image (runs 44313753659, 44317425288, 44320959119; two or three copies per variant):

- Parallel testing, no preparation (before this task): 3:50–11:50, peak load 538–645.
- Serial testing, no preparation: 3:24 and 7:31, peak 185–584 — the base simulator still boots for the first time during the tests.
- Pre-booted simulator, parallel testing: 2:49 and 5:10, peak 103–267 — the clone still boots during the tests.
- Pre-booted simulator, serial testing: 1:05 and 1:15, peak 52–133. Booting in its own step takes 101–117 s.

The owner chose the last variant on 2026-11-18.

### Constraints

- Do not hide the problem: no retries, no skipped tests, no longer timeouts.
- The local `deno task check` stays as it is: parallel testing is fast on a developer machine and prints a line per test.
- `deno task ci` remains the same command a developer can run.

## Definition of Done

- [x] CI boots the test simulator in its own step and waits until the boot is over before the build starts.
  - Evidence: `grep -n "simctl bootstatus" .github/workflows/ci.yml`
- [x] CI runs the unit tests without parallel testing; local runs keep it.
  - Evidence: `grep -n "TEST_PARALLEL" .github/workflows/ci.yml scripts/config.ts`
- [x] `deno task check` passes locally (279 tests, 2026-11-18).
  - Evidence: `SKIP_LOG_STREAM=1 NO_COLOR=1 deno task check`
- [x] A CI run on `main` with this change passes (run 44325666164: tests 1 min, job 8 min 19 s).
  - Evidence: `gh run list --branch main -L 1 --json conclusion -q '.[0].conclusion'` prints `success`

## Solution

1. `scripts/config.ts`: `PARALLEL_TESTING`, read from `TEST_PARALLEL` (default `YES`), next to the other test-destination settings, with the measurement that justifies it.
2. `scripts/tests.ts`: pass `PARALLEL_TESTING` to `-parallel-testing-enabled` in both `buildAndTest` and `test`.
3. `.github/workflows/ci.yml`: after "Pick a simulator", a "Boot simulator" step runs `xcrun simctl boot` and `xcrun simctl bootstatus -b` on `$TEST_SIMULATOR_ID`; the `deno task ci` step sets `TEST_PARALLEL: "NO"`.
4. README "CI/CD": say that CI tests on a pre-booted simulator without parallel testing, and why.
5. Run `deno task check`, commit, push after the owner's OK, confirm the CI run on `main`.

## Follow-ups

- `actionlint` warns SC2211 on the "Toolchain" step (`.tools/swiftformat-*/swiftformat --version`: a glob used as a command name). It predates this task.
- Tuist 4.218 cannot generate the project inside a `git worktree` checkout ("Couldn't locate the root directory": it looks for a `.git` directory, and a worktree has a `.git` file). `deno task check` has to run in a plain clone or the main checkout.

## Status

- State: done
- Needs from the operator: nothing
- Not verified: that cancellations are gone for good (one green run on the fix, the old rate was about one run in three); how a failing test looks in the CI log without parallel testing (no failing run was produced)
- Branch: fix `9f89ad1` and closing commit `ca462c3` are pushed to `main`; this status section is committed on local branch `status/ci-simulator-boot-storm`, not pushed; the local main checkout is still at 92ebd9a
- Told directly by the operator: nobody cancelled the runs by hand; chose a pre-booted simulator with serial tests on CI over keeping parallel testing; approved pushing the fix and the closing commit to `main`; approved deleting the diagnostic branch `diag/ci-test-hang`
- Updated: 2026-11-18 17:27 EET
