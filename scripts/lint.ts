/**
 * `deno task lint` — SwiftLint, then Periphery's dead-code scan when it is
 * installed.
 *
 * SwiftLint runs twice on purpose: `--fix` first, so mechanical violations are
 * repaired rather than reported, then `--strict`, which fails on anything left.
 * Any output at all from either pass is a failure — `--quiet` silences the
 * progress chatter, so what remains is findings.
 */

import { exists, fail, run, walk } from "./lib.ts";
import { step } from "./config.ts";

async function swiftlint(args: string[], label: string): Promise<void> {
  const result = await run("swiftlint", { args, allowFailure: true, capture: true });
  // Only stdout carries findings. SwiftLint writes configuration and
  // deprecation notices to stderr, and failing on those would make the gate
  // red for things that are not violations — pass them through instead.
  if (result.stderr.trim()) console.error(result.stderr.trim());
  if (result.stdout.trim()) {
    console.log(result.stdout.trim());
    fail(`${label} found issues`);
  }
}

/** True when the tool resolves in PATH. */
async function hasTool(tool: string): Promise<boolean> {
  const which = await run("which", { args: [tool], allowFailure: true, capture: true });
  return which.code === 0;
}

/** SwiftLint alone — cheap enough to run before anything has been built. */
export async function swiftLint(): Promise<void> {
  await step("Running SwiftLint", async () => {
    await swiftlint(["lint", "--fix", "--quiet"], "SwiftLint");
    await swiftlint(["lint", "--strict", "--quiet"], "SwiftLint (strict)");
  });
}

/**
 * Fail unless every Swift source is older than the index store.
 *
 * `--skip-build` makes Periphery trust an index somebody else produced, and an
 * index older than the sources describes code that no longer exists — the scan
 * would then pass a declaration that is dead in the working tree. Comparing
 * modification times is enough to catch that: the alternative, trusting the
 * caller, is what makes a fast gate quietly stop checking.
 */
async function assertIndexIsCurrent(indexStore: string): Promise<void> {
  /** Modification time of the newest file under `root`, and which file it is. */
  async function newestUnder(root: string, extensions: string[]) {
    let time = 0;
    let path = "";
    for await (const found of walk(root, extensions)) {
      const mtime = (await Deno.stat(found)).mtime?.getTime() ?? 0;
      if (mtime > time) {
        time = mtime;
        path = found;
      }
    }
    return { time, path };
  }

  // The newest file INSIDE the store, not the store directory itself: a build
  // rewrites unit files under it and never touches the top-level directory's
  // own timestamp, so comparing against that would call every index stale.
  // Measured 2026-08-08: directory stamped 21:43, files written 03:56.
  const index = await newestUnder(indexStore, [""]);
  const source = await newestUnder("src", [".swift"]);
  if (source.time > index.time) {
    const behind = Math.round((source.time - index.time) / 1000);
    fail(
      `index store ${indexStore} is ${behind}s behind ${source.path} — ` +
        "it describes code that has since changed; rebuild before scanning",
    );
  }
}

/**
 * Periphery's dead-code scan.
 *
 * Given the index store of a build that already happened, Periphery skips its
 * own clean build — which is essentially the entire cost of this step: 51 s
 * became 3 s in the gate, where the test run has just written that index
 * anyway. Called with no argument (`deno task lint` on its own, nothing built
 * yet) it honours `clean_build: true` from `.periphery.yml` and pays for the
 * build. Which mode ran is printed, because the two differ by a minute and a
 * reader of the log should not have to infer it.
 */
export async function periphery(indexStore?: string): Promise<void> {
  await step("Running Periphery (dead code analysis)", async () => {
    // Periphery is deliberately absent on CI: its scan needs a second full
    // index build. Skipping with a warning keeps the gate usable there.
    if (!(await hasTool("periphery"))) {
      console.log(
        "Periphery not found, skipping dead code analysis. Install with: brew install peripheryapp/periphery/periphery",
      );
      return;
    }
    // A caller that names an index store expects the build to have produced it,
    // from the sources as they are now. Both halves have to be checked: a
    // missing index would silently turn a 3 s step into a 51 s one, and a stale
    // one is worse — Periphery would scan yesterday's code and pass a file that
    // is dead today. Inside the gate the build runs immediately before this, so
    // neither can happen; the checks exist for every other caller.
    if (indexStore !== undefined) {
      if (!(await exists(indexStore))) {
        fail(`index store ${indexStore} is missing — the build that writes it did not run`);
      }
      await assertIndexIsCurrent(indexStore);
    }
    const args = ["scan", "--config", ".periphery.yml", "--format", "xcode", "--strict", "--quiet"];
    if (indexStore !== undefined) {
      console.log(`    reusing the index store at ${indexStore}`);
      args.push("--skip-build", "--index-store-path", indexStore);
    } else {
      console.log("    no index store given — Periphery builds its own");
    }
    const scan = await run("periphery", { args, allowFailure: true });
    if (scan.code !== 0) fail("Periphery found dead code");
  });
}

/** `deno task lint` — both linters standalone, building whatever they need. */
export async function lint(): Promise<void> {
  await swiftLint();
  await periphery();
}

if (import.meta.main) await lint();
