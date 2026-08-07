/** `deno task clean` — remove every build, cache, log and temporary file. */

import { run } from "./lib.ts";
import { step } from "./config.ts";

const DIRS = ["build", ".build", ".swiftpm", "coverage"];
const HOME = Deno.env.get("HOME") ?? "";

await step("Full clean", async () => {
  for (const dir of DIRS) await Deno.remove(dir, { recursive: true }).catch(() => {});
  await Deno.remove(`${HOME}/Library/Developer/Xcode/DerivedData`, { recursive: true })
    .catch(() => {});

  // Artifacts scattered through the tree. `find` walks into directories it has
  // just deleted and reports it, so a non-zero status here is noise, not failure.
  await run("find", {
    args: [".", "-type", "d", "-name", "DerivedData", "-exec", "rm", "-rf", "{}", "+"],
    allowFailure: true,
  });
  for (const pattern of ["*.log", "*.tmp", "*.temp", "*.xcresult", "*.ipa", "*.dSYM"]) {
    await run("find", {
      args: [".", "-maxdepth", "3", "-name", pattern, "-exec", "rm", "-rf", "{}", "+"],
      allowFailure: true,
    });
  }
});
