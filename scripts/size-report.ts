/**
 * `deno task size-report` — build the ShareExtension for a device and report
 * its size. App extensions have a hard memory/size ceiling; 20 MB is the line
 * this project holds.
 */

import { fail, run, section, walk } from "./lib.ts";
import { step } from "./config.ts";
import { generate } from "./generate.ts";

const LIMIT_MB = 20;

await generate();

/** Where the device build lands; the appex sits under `Build/Products/<cfg>-<sdk>/`. */
const DERIVED_DATA = "build/DerivedData_SizeReport";

await step("Cleaning build artifacts", async () => {
  await Deno.remove("build", { recursive: true }).catch(() => {});
});

// Built through the xcodebuild wrapper rather than `tuist build`, because only
// xcodebuild honours `-sdk iphoneos`: Tuist picks the destination itself and
// files the products by ITS notion of configuration and platform. The previous
// form passed `-configuration Release -sdk iphoneos` after `--`, and Tuist
// happily produced `Debug-iphonesimulator` — so this gate had been measuring a
// debug simulator build against a limit that exists for the device binary.
// Signing is off: the size of the payload does not depend on it, and a device
// build would otherwise need a provisioning profile.
await step("Building ShareExtension for size report (Release/iphoneos)", async () => {
  await run("tuist", {
    args: [
      "xcodebuild",
      "build",
      "-scheme",
      "ShareExtension",
      "-configuration",
      "Release",
      "-sdk",
      "iphoneos",
      "-derivedDataPath",
      DERIVED_DATA,
      "CODE_SIGNING_ALLOWED=NO",
      "-quiet",
    ],
  });
});

/** Total size of a directory tree, in bytes. */
async function treeSize(root: string): Promise<number> {
  let total = 0;
  // "" is a suffix of every file name, so this walks the whole tree.
  for await (const path of walk(root, [""])) {
    total += (await Deno.stat(path)).size;
  }
  return total;
}

// Only the device build counts. The tree is cleaned above, so anything found
// here was produced by the step above and nothing else.
const products = `${DERIVED_DATA}/Build/Products`;
const appexes: string[] = [];
for await (const entry of Deno.readDir(products)) {
  if (!entry.isDirectory || !entry.name.endsWith("-iphoneos")) continue;
  for await (const inner of Deno.readDir(`${products}/${entry.name}`)) {
    if (inner.name === "ShareExtension.appex") {
      appexes.push(`${products}/${entry.name}/${inner.name}`);
    }
  }
}
if (appexes.length === 0) fail(`ShareExtension.appex not found under ${products}/*-iphoneos`);

let over = false;
for (const appex of appexes) {
  const bytes = await treeSize(appex);
  const mb = bytes / 1024 / 1024;
  console.log(`ShareExtension.appex at ${appex} size: ${mb.toFixed(2)} MB (${bytes} bytes)`);
  if (mb > LIMIT_MB) {
    console.error(`Error: ShareExtension size at ${appex} exceeds ${LIMIT_MB}MB!`);
    over = true;
  }
}
if (over) fail("ShareExtension is over the size limit");
section("size-report: within limit");
