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

await step("Cleaning build artifacts", async () => {
  await Deno.remove("build", { recursive: true }).catch(() => {});
});

await step("Building ShareExtension for size report (Release/iphoneos)", async () => {
  await run("tuist", {
    args: [
      "build",
      "ShareExtension",
      "--build-output-path",
      "build/Products",
      "--",
      "-configuration",
      "Release",
      "-sdk",
      "iphoneos",
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

const appexes: string[] = [];
for await (const entry of Deno.readDir("build/Products")) {
  if (!entry.isDirectory) continue;
  for await (const inner of Deno.readDir(`build/Products/${entry.name}`)) {
    if (inner.name === "ShareExtension.appex") {
      appexes.push(`build/Products/${entry.name}/${inner.name}`);
    }
  }
}
if (appexes.length === 0) fail("ShareExtension.appex not found");

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
