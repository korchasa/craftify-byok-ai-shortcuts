/** `deno task init` — install the CLI tools the other tasks call. */

import { run, section } from "./lib.ts";

const TOOLS = ["tuist", "swiftlint", "swiftformat", "swiftgen", "gitleaks"];

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
section("All dependencies checked");
