/**
 * `deno task prod` — the same loop as `dev`, but Release: optimizations on and
 * debug-only code compiled out, which is the configuration `dist` ships.
 * Running it on the simulator is the cheapest way to catch behaviour that only
 * differs under Release.
 */

import { runOnSimulator } from "./simulator.ts";

await runOnSimulator("Release");
