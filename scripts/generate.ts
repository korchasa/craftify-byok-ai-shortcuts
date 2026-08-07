/**
 * `deno task generate` — SwiftGen (localized string enums) then Tuist (the
 * Xcode workspace). Everything else depends on this having run.
 */

import { fail, run } from "./lib.ts";
import { step } from "./config.ts";

/**
 * Output directories declared in swiftgen.yml.
 *
 * SwiftGen does not create its own output directories, and a missing one is
 * reported as an error while the process still exits 0 — so on a fresh clone
 * (CI, or after a full clean) the strings enum is silently never written and
 * the failure only surfaces much later as "cannot find 'L10n' in scope". Every
 * output directory in swiftgen.yml must be listed here.
 */
const GENERATED_DIRS = [
  "src/MainApp/Resources/Generated",
  "src/ShareExtension/Resources/Generated",
  "src/Common/Generated",
];

/** Files SwiftGen must have written by the time it exits. */
const GENERATED_FILES = [
  "src/MainApp/Resources/Generated/Strings.swift",
  "src/ShareExtension/Resources/Generated/Strings.swift",
];

export async function generate(args: string[] = []): Promise<void> {
  for (const dir of GENERATED_DIRS) await Deno.mkdir(dir, { recursive: true });

  await step("Running SwiftGen", async () => {
    await run("swiftgen", { args });
    for (const file of GENERATED_FILES) {
      const stat = await Deno.stat(file).catch(() => null);
      if (!stat || stat.size === 0) {
        fail(`SwiftGen wrote no ${file} — check swiftgen.yml against GENERATED_DIRS`);
      }
    }
  });

  await step("Running Tuist generate", async () => {
    await run("tuist", { args: ["generate", ...args, "--no-open"] });
  });
}

if (import.meta.main) await generate(Deno.args);
