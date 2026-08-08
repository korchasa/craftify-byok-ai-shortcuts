/**
 * Constants and the section helper shared by the task scripts.
 *
 * Simulator ids default to a developer's own device and are overridden by
 * SIMULATOR_ID / TEST_SIMULATOR_ID — CI resolves a real one at run time,
 * because the default UDID does not exist on a fresh runner.
 */

export const BUNDLE_ID = "dev.korchasa.Craftify";

export const SIMULATOR_ID = Deno.env.get("SIMULATOR_ID") ??
  "7CF4E738-10F4-4DFD-93E0-041CAB1CA888";
export const TEST_SIMULATOR_ID = Deno.env.get("TEST_SIMULATOR_ID") ?? SIMULATOR_ID;

export const DEST_SIMULATOR = `id=${SIMULATOR_ID},arch=arm64`;
export const DEST_TEST_SIMULATOR = `id=${TEST_SIMULATOR_ID},arch=arm64`;

/**
 * One derived-data directory for every simulator build in the gate.
 *
 * The test run and the smoke run compile the same targets in the same
 * configuration for the same simulator, so they share the compilation cache
 * instead of each paying for a full build: sharing it took the smoke build from
 * 71 s to 10 s. Its index store is also what lets Periphery skip its own clean
 * build (51 s → 3 s).
 */
export const DERIVED_DATA = "build/DerivedData_FastCheck";

/** Index store written by any build into `DERIVED_DATA`; input for Periphery. */
export const INDEX_STORE = `${DERIVED_DATA}/Index.noindex/DataStore`;

/** Skip attaching the interactive log stream after a simulator launch. */
export const SKIP_LOG_STREAM = Deno.env.get("SKIP_LOG_STREAM") === "1";

/**
 * Run `body` inside a named section, printing how long it took.
 *
 * Build steps here run for minutes; a bare command with no boundary makes a log
 * impossible to read after the fact.
 */
export async function step<T>(title: string, body: () => Promise<T>): Promise<T> {
  console.log("========================================");
  console.log(`>>> ${title}`);
  const started = Date.now();
  try {
    return await body();
  } finally {
    const elapsed = Math.round((Date.now() - started) / 1000);
    console.log(`<<< Section finished in ${elapsed}s`);
    console.log("========================================");
  }
}
