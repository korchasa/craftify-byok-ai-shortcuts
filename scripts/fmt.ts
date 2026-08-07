/**
 * `deno task fmt` — apply formatting in place: SwiftFormat over the Swift
 * sources, `deno fmt` over the task scripts.
 */

import { run } from "./lib.ts";
import { step } from "./config.ts";

export async function fmt(args: string[] = []): Promise<void> {
  await step("Running SwiftFormat", async () => {
    await run("swiftformat", { args: [".", "--quiet", ...args] });
  });
  await step("Running deno fmt", async () => {
    await run("deno", { args: ["fmt"] });
  });
}

if (import.meta.main) await fmt(Deno.args);
