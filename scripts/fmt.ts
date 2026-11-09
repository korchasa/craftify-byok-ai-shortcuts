/**
 * `deno task fmt` — apply formatting in place: SwiftFormat over the Swift
 * sources, `deno fmt` over the task scripts.
 *
 * SwiftFormat is the pinned release `deno task init` installed, never the one
 * on PATH: a different release formats the same tree differently.
 */

import { exists, fail, run } from "./lib.ts";
import { step, SWIFTFORMAT_BIN, SWIFTFORMAT_VERSION } from "./config.ts";

export async function fmt(args: string[] = []): Promise<void> {
  await step(`Running SwiftFormat ${SWIFTFORMAT_VERSION}`, async () => {
    if (!(await exists(SWIFTFORMAT_BIN))) {
      fail(
        `SwiftFormat ${SWIFTFORMAT_VERSION} is not installed at ${SWIFTFORMAT_BIN}; ` +
          "run `deno task init` to download it",
      );
    }
    await run(SWIFTFORMAT_BIN, { args: [".", "--quiet", ...args] });
  });
  await step("Running deno fmt", async () => {
    await run("deno", { args: ["fmt"] });
  });
}

if (import.meta.main) await fmt(Deno.args);
