/** `deno task init` — install the CLI tools the other tasks call. */

import { exists, fail, run, section } from "./lib.ts";
import {
  SWIFTFORMAT_BIN,
  SWIFTFORMAT_SHA256,
  SWIFTFORMAT_URL,
  SWIFTFORMAT_VERSION,
} from "./config.ts";

/** Taken from Homebrew at whatever version it has; none of them rewrites sources. */
const TOOLS = ["tuist", "swiftlint", "swiftgen", "gitleaks"];

section("Checking CLI tools via Homebrew");
for (const tool of TOOLS) {
  const which = await run("which", { args: [tool], allowFailure: true, capture: true });
  if (which.code === 0) {
    console.log(`${tool} is already installed`);
    continue;
  }
  console.log(`Installing ${tool}...`);
  await run("brew", { args: ["install", tool] });
}

section(`Checking SwiftFormat ${SWIFTFORMAT_VERSION}`);
if (await exists(SWIFTFORMAT_BIN)) {
  console.log(`SwiftFormat ${SWIFTFORMAT_VERSION} is already installed`);
} else {
  await installSwiftFormat();
}
section("All dependencies checked");

/** Download the pinned release, refuse it unless its digest matches, unpack it. */
async function installSwiftFormat(): Promise<void> {
  console.log(`Downloading ${SWIFTFORMAT_URL}`);
  const response = await fetch(SWIFTFORMAT_URL);
  if (!response.ok) {
    fail(`download of SwiftFormat ${SWIFTFORMAT_VERSION} answered HTTP ${response.status}`);
  }
  const archive = new Uint8Array(await response.arrayBuffer());
  const digest = Array.from(new Uint8Array(await crypto.subtle.digest("SHA-256", archive)))
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
  if (digest !== SWIFTFORMAT_SHA256) {
    fail(
      `SwiftFormat ${SWIFTFORMAT_VERSION} archive has SHA-256 ${digest}, ` +
        `expected ${SWIFTFORMAT_SHA256}`,
    );
  }

  const dir = SWIFTFORMAT_BIN.slice(0, SWIFTFORMAT_BIN.lastIndexOf("/"));
  const zip = await Deno.makeTempFile({ suffix: ".zip" });
  try {
    await Deno.writeFile(zip, archive);
    await Deno.mkdir(dir, { recursive: true });
    await run("ditto", { args: ["-x", "-k", zip, dir] });
  } finally {
    await Deno.remove(zip);
  }

  const version = (await run(SWIFTFORMAT_BIN, { args: ["--version"], capture: true })).stdout
    .trim();
  if (version !== SWIFTFORMAT_VERSION) {
    fail(`${SWIFTFORMAT_BIN} reports version ${version}, expected ${SWIFTFORMAT_VERSION}`);
  }
  console.log(`Installed SwiftFormat ${version} at ${SWIFTFORMAT_BIN}`);
}
