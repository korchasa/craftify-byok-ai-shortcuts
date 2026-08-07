/** `deno task logs` — tail MainApp and ShareExtension logs from the booted simulator. */

import { logs } from "./simulator.ts";

await logs();
