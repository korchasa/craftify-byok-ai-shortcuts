/**
 * `deno task dev` — generate the project, build MainApp (Debug), install it on
 * the simulator, launch it and tail its logs. Ends on Ctrl-C.
 */

import { runOnSimulator } from "./simulator.ts";

await runOnSimulator("Debug");
