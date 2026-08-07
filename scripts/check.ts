/**
 * `deno task check` — everything, ending with a smoke run on the simulator.
 * `deno task ci` — the same minus the simulator, which is what CI executes.
 *
 * The order fails cheapest first. A green CI run therefore means what a green
 * local `check` means, minus the smoke run — and both exit with a status: the
 * smoke run does not attach the endless log stream (use `deno task dev` for
 * that).
 */

import { checkTooling, section } from "./lib.ts";
import { step } from "./config.ts";
import { generate } from "./generate.ts";
import { fmt } from "./fmt.ts";
import { lint } from "./lint.ts";
import { checkLocalization, commentScan, secretScan } from "./scans.ts";
import { buildAndTest } from "./tests.ts";
import { deploySimulator } from "./simulator.ts";

/** Every check that needs no simulator UI. `ci` is exactly this. */
export async function checkCore(): Promise<void> {
  await step("Tooling (deno fmt --check, lint, type-check)", checkTooling);
  await secretScan();
  await generate();
  await fmt();
  await lint();
  await checkLocalization();
  await buildAndTest();
  await commentScan();
}

if (import.meta.main) {
  const ciOnly = Deno.args[0] === "ci";
  await checkCore();
  if (!ciOnly) {
    await deploySimulator({ configuration: "Debug", streamLogs: false });
  }
  section(ciOnly ? "ci: OK" : "check: OK");
}
