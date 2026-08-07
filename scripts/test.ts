/**
 * `deno task test [test-id]` — the whole suite, or one target or case:
 *
 *   deno task test
 *   deno task test MainAppUnitTests/TestExample
 */

import { test } from "./tests.ts";

await test(Deno.args[0]);
