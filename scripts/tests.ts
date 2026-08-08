/**
 * Building and running the test suite on the simulator.
 *
 * `--no-selective-testing` is not optional: without it Tuist skips targets it
 * considers unchanged and exits 0 reporting "has no tests to run, finishing
 * early", so the gate goes green having run nothing.
 */

import { fail, run } from "./lib.ts";
import { DERIVED_DATA, DEST_TEST_SIMULATOR, step } from "./config.ts";

const SCHEME = "AllTests";

function testArgs(derivedData: string, resultBundle: string): string[] {
  return [
    "--",
    "-sdk",
    "iphonesimulator",
    "-destination",
    DEST_TEST_SIMULATOR,
    "-derivedDataPath",
    derivedData,
    "-parallel-testing-enabled",
    "YES",
    "-parallel-testing-worker-count",
    "4",
    "-resultBundlePath",
    resultBundle,
    "-testLanguage",
    "en",
    "-testRegion",
    "US",
    "-quiet",
  ];
}

/**
 * Every value stored under `key`, at any depth. The result bundle nests the
 * failure list differently depending on how the run ended, so it is searched
 * rather than indexed.
 */
function collect(node: unknown, key: string): unknown[] {
  if (Array.isArray(node)) return node.flatMap((child) => collect(child, key));
  if (node && typeof node === "object") {
    return Object.entries(node).flatMap(([name, value]) =>
      name === key ? [value] : collect(value, key)
    );
  }
  return [];
}

/** Build every target, then run the whole suite. Used by `check` and `ci`. */
export async function buildAndTest(): Promise<void> {
  // The shared cache: the smoke run builds into it too, and Periphery reads its
  // index store. Changing it here changes it for both.
  const derivedData = DERIVED_DATA;
  const resultBundle = "build/Results/AllTests.xcresult";
  await Deno.remove(resultBundle, { recursive: true }).catch(() => {});

  await step("Fast build+test (MainApp, ShareExtension, AllUnitTests)", async () => {
    await run("tuist", {
      args: [
        "build",
        SCHEME,
        "--configuration",
        "Debug",
        "--",
        "-sdk",
        "iphonesimulator",
        "-destination",
        DEST_TEST_SIMULATOR,
        "-derivedDataPath",
        derivedData,
        "-quiet",
      ],
    });
    await run("tuist", {
      args: [
        "test",
        SCHEME,
        "--configuration",
        "Debug",
        "--no-selective-testing",
        ...testArgs(derivedData, resultBundle),
      ],
    });
  });
}

/**
 * `deno task test [test-id]` — the whole suite, or one target/case
 * (e.g. `MainAppUnitTests/TestExample`).
 */
export async function test(testId?: string): Promise<void> {
  const derivedData = `build/DerivedData_Test_${SCHEME}`;
  const resultBundle = `build/Results/${SCHEME}.xcresult`;
  await Deno.remove(resultBundle, { recursive: true }).catch(() => {});

  const selection = testId ? ["--test-targets", testId] : [];
  const result = await step(`Running tests: ${testId ?? "all"}`, () =>
    run("tuist", {
      args: [
        "test",
        SCHEME,
        ...selection,
        "--no-selective-testing",
        "--configuration",
        "Debug",
        ...testArgs(derivedData, resultBundle),
      ],
      allowFailure: true,
    }));

  if (result.code === 0) return;

  // The result bundle names the failing cases; the raw xcodebuild tail rarely does.
  const summary = await run("xcrun", {
    args: ["xcresulttool", "get", "--legacy", "--path", resultBundle, "--format", "json"],
    allowFailure: true,
    capture: true,
  });
  if (summary.code === 0) {
    const found = collect(JSON.parse(summary.stdout), "testFailureSummaries");
    if (found.length > 0) {
      console.error("Test failures summary:");
      found.forEach((entry) => console.error(JSON.stringify(entry, null, 2)));
    }
  }
  fail(`tests failed (result bundle: ${resultBundle})`);
}
