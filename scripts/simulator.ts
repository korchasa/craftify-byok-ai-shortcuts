/**
 * Simulator handling: boot, install, launch, and the log stream.
 *
 * Used by `dev` (Debug), `prod` (Release) and the smoke run at the end of
 * `check`. The smoke run does NOT attach the log stream: a verification gate
 * has to exit with a status, and `log stream` never ends on its own.
 */

import { exists, fail, run } from "./lib.ts";
import {
  BUNDLE_ID,
  DERIVED_DATA_SIM,
  DEST_SIMULATOR,
  SIMULATOR_ID,
  SKIP_LOG_STREAM,
  step,
} from "./config.ts";
import { generate } from "./generate.ts";

const LOG_PREDICATE =
  '(subsystem == "Internal") && (process == "MainApp" OR process == "ShareExtension")';

/** Where the streamed log is mirrored, so it can be grepped after the fact. */
const LOG_FILE = "emulator.log";

/** State of the configured simulator, or null when it does not exist here. */
async function simulatorState(): Promise<string | null> {
  const listed = await run("xcrun", {
    args: ["simctl", "list", "devices", "--json"],
    capture: true,
  });
  const devices: Record<string, Array<{ udid: string; state: string }>> =
    JSON.parse(listed.stdout).devices;
  for (const runtime of Object.values(devices)) {
    const match = runtime.find((device) => device.udid === SIMULATOR_ID);
    if (match) return match.state;
  }
  return null;
}

async function bootAndWait(): Promise<void> {
  const state = await simulatorState();
  if (state === null) {
    console.error(
      `Simulator with UDID ${SIMULATOR_ID} not found.\n` +
        "Set SIMULATOR_ID to an existing device — `xcrun simctl list devices available` lists them.",
    );
    fail("no such simulator");
  }
  if (state === "Booted") {
    console.log(`Simulator ${SIMULATOR_ID} already booted.`);
    return;
  }
  await step(`Booting simulator ${SIMULATOR_ID} (was ${state})`, async () => {
    await run("xcrun", { args: ["simctl", "boot", SIMULATOR_ID] });
    await run("xcrun", { args: ["simctl", "bootstatus", SIMULATOR_ID, "-b"] });
  });
}

/** Install with backoff: a freshly booted simulator refuses the first attempts. */
async function install(appPath: string): Promise<void> {
  if (!(await exists(appPath))) fail(`MainApp.app not found at ${appPath}`);
  for (let attempt = 1; attempt <= 5; attempt++) {
    const result = await run("xcrun", {
      args: ["simctl", "install", SIMULATOR_ID, appPath],
      allowFailure: true,
    });
    if (result.code === 0) return;
    const delay = 2 ** (attempt - 1);
    console.log(`Install attempt ${attempt} failed, retrying in ${delay}s...`);
    await new Promise((resolve) => setTimeout(resolve, delay * 1000));
  }
  fail("failed to install the app after 5 attempts");
}

export interface DeployOptions {
  configuration: "Debug" | "Release";
  /** Attach the (endless) log stream after launching. Never true for a gate. */
  streamLogs: boolean;
}

/** Build the app for the simulator, install it and launch it. */
export async function deploySimulator(opts: DeployOptions): Promise<void> {
  const { configuration } = opts;

  await step("Opening Simulator", async () => {
    await run("open", { args: ["-a", "Simulator"] });
  });

  await step(`Building MainApp for Simulator (${configuration})`, async () => {
    await Deno.remove(DERIVED_DATA_SIM, { recursive: true }).catch(() => {});
    await run("tuist", {
      args: [
        "build",
        "MainApp",
        "--build-output-path",
        "build/Products",
        "--",
        "-configuration",
        configuration,
        "-sdk",
        "iphonesimulator",
        "-destination",
        DEST_SIMULATOR,
        "-quiet",
      ],
    });
  });

  await bootAndWait();

  const appPath = `build/Products/${configuration}-iphonesimulator/MainApp.app`;
  await step(`Installing app to simulator: ${appPath}`, () => install(appPath));

  await step("Launching app in simulator", async () => {
    await run("xcrun", { args: ["simctl", "launch", SIMULATOR_ID, BUNDLE_ID] });
  });

  if (!opts.streamLogs || SKIP_LOG_STREAM) {
    if (opts.streamLogs) console.log("Skipping log stream due to SKIP_LOG_STREAM=1");
    return;
  }
  await logs();
}

/**
 * Stream MainApp and ShareExtension logs from the booted simulator, mirroring
 * them into emulator.log so the session can be grepped afterwards. Ends only on
 * Ctrl-C.
 */
export async function logs(): Promise<void> {
  console.log(`==> Streaming logs to the terminal and ${LOG_FILE} (Ctrl-C to stop)`);
  const command = new Deno.Command("xcrun", {
    args: [
      "simctl",
      "spawn",
      "booted",
      "log",
      "stream",
      "--predicate",
      LOG_PREDICATE,
      "--style",
      "syslog",
      "--level=debug",
    ],
    stdout: "piped",
    stderr: "inherit",
  });
  const child = command.spawn();
  const file = await Deno.open(LOG_FILE, { create: true, write: true, truncate: true });
  await child.stdout
    .pipeThrough(
      new TransformStream<Uint8Array, Uint8Array>({
        transform(chunk, controller) {
          Deno.stdout.writeSync(chunk);
          controller.enqueue(chunk);
        },
      }),
    )
    .pipeTo(file.writable);
  await child.status;
}

/** `dev`/`prod`: regenerate the project, then run on the simulator. */
export async function runOnSimulator(configuration: "Debug" | "Release"): Promise<void> {
  await generate();
  await deploySimulator({ configuration, streamLogs: true });
}
