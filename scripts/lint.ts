/**
 * `deno task lint` — SwiftLint, then Periphery's dead-code scan when it is
 * installed.
 *
 * SwiftLint runs twice on purpose: `--fix` first, so mechanical violations are
 * repaired rather than reported, then `--strict`, which fails on anything left.
 * Any output at all from either pass is a failure — `--quiet` silences the
 * progress chatter, so what remains is findings.
 */

import { fail, run } from "./lib.ts";
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

export async function lint(): Promise<void> {
  await step("Running SwiftLint", async () => {
    await swiftlint(["lint", "--fix", "--quiet"], "SwiftLint");
    await swiftlint(["lint", "--strict", "--quiet"], "SwiftLint (strict)");
  });

  await step("Running Periphery (dead code analysis)", async () => {
    // Periphery is deliberately absent on CI: its scan needs a second full
    // index build. Skipping with a warning keeps the gate usable there.
    if (!(await hasTool("periphery"))) {
      console.log(
        "Periphery not found, skipping dead code analysis. Install with: brew install peripheryapp/periphery/periphery",
      );
      return;
    }
    const scan = await run("periphery", {
      args: ["scan", "--config", ".periphery.yml", "--format", "xcode", "--strict", "--quiet"],
      allowFailure: true,
    });
    if (scan.code !== 0) fail("Periphery found dead code");
  });
}

if (import.meta.main) await lint();
