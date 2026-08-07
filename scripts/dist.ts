/**
 * `deno task dist` — UNSIGNED App Store archive.
 *
 * Signing, packaging and upload all happen outside this repository — NO signing
 * happens here. The output path is part of that contract and must stay exactly
 * `build/Craftify.xcarchive`.
 */

import { exists, fail, run, section } from "./lib.ts";
import { step } from "./config.ts";
import { generate } from "./generate.ts";

const ARCHIVE = "build/Craftify.xcarchive";

// Regenerate the Tuist project from scratch: drop the generated
// workspace/project (both gitignored) so `tuist generate` cannot trip on a
// stale Package.resolved symlink left over from an earlier location of the repo.
await Deno.remove("Craftify.xcworkspace", { recursive: true }).catch(() => {});
await Deno.remove("Craftify.xcodeproj", { recursive: true }).catch(() => {});

await generate();

await step("Archiving MainApp for App Store (unsigned)", async () => {
  await Deno.remove(ARCHIVE, { recursive: true }).catch(() => {});
  await run("xcodebuild", {
    args: [
      "archive",
      "-workspace",
      "Craftify.xcworkspace",
      "-scheme",
      "MainApp",
      "-configuration",
      "Release",
      "-destination",
      "generic/platform=iOS",
      "-archivePath",
      ARCHIVE,
      "CODE_SIGNING_ALLOWED=NO",
      "CODE_SIGNING_REQUIRED=NO",
      "CODE_SIGN_STYLE=Manual",
      "CODE_SIGN_IDENTITY=",
      "-quiet",
    ],
    // PATH=/usr/bin so xcodebuild's copy phase resolves the system rsync, not
    // the Homebrew one (the same problem shows up later, on -exportArchive).
    env: { PATH: `/usr/bin:${Deno.env.get("PATH") ?? ""}` },
  });
});

if (!(await exists(ARCHIVE))) fail(`archive was not produced at ${ARCHIVE}`);
section(`Unsigned archive: ${ARCHIVE}`);
