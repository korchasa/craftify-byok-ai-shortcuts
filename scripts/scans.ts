/**
 * Source scans that need no build: leftover work markers, localization key
 * parity, and secrets.
 */

import { exists, fail, run, scanFiles } from "./lib.ts";
import { step } from "./config.ts";

/** Work markers and stray debug output that must not reach a shipped build. */
const MARKERS = /TODO|FIXME|print\(|debugPrint\(/;

/** Text file types under src/. Binary resources (PNGs) are skipped, not read. */
const SCANNED = [".swift", ".strings", ".json", ".plist"];

export async function commentScan(): Promise<void> {
  await step("Scanning for TODO/FIXME/print/debugPrint", async () => {
    const hits = await scanFiles(["src"], SCANNED, MARKERS);
    if (hits.length > 0) {
      hits.forEach((hit) => console.log(hit));
      fail("TODO/FIXME/print/debugPrint found");
    }
  });
}

/** Localized string bundles, each with `en.lproj` as the reference locale. */
const RESOURCE_DIRS = [
  "src/MainApp/Resources",
  "src/ShareExtension/Resources",
  "src/Common/Resources",
];

const ENUM_FILE = "src/Common/Sources/Models/UserFacingErrorKey.swift";
const EXT_STRINGS = "src/ShareExtension/Resources/en.lproj/Localizable.strings";

/** The keys declared in a .strings file, in file order. */
async function stringKeys(path: string): Promise<string[]> {
  const text = await Deno.readTextFile(path);
  return text.split("\n")
    .map((line) => /^"([^"]*)"/.exec(line)?.[1])
    .filter((key): key is string => key !== undefined);
}

export async function checkLocalization(): Promise<void> {
  await step("Checking localization key parity (all locales vs en, 3 bundles)", async () => {
    let failed = false;

    for (const res of RESOURCE_DIRS) {
      const reference = `${res}/en.lproj/Localizable.strings`;
      if (!(await exists(reference))) {
        console.error(`Missing reference locale: ${reference}`);
        failed = true;
        continue;
      }
      const expected = new Set(await stringKeys(reference));

      for await (const entry of Deno.readDir(res)) {
        if (!entry.isDirectory || !entry.name.endsWith(".lproj")) continue;
        const locale = entry.name.replace(/\.lproj$/, "");
        if (locale === "en") continue;

        const actual = new Set(await stringKeys(`${res}/${entry.name}/Localizable.strings`));
        const missing = [...expected].filter((key) => !actual.has(key)).sort();
        const extra = [...actual].filter((key) => !expected.has(key)).sort();
        if (missing.length === 0 && extra.length === 0) continue;

        console.error(`Key mismatch in ${res} — ${locale} vs en:`);
        missing.forEach((key) => console.error(`  only in en: "${key}"`));
        extra.forEach((key) => console.error(`  only in ${locale}: "${key}"`));
        failed = true;
      }
    }

    // A key declared in code but absent from the strings file is not caught by
    // comparing locales with each other: localizedString(forKey:value:nil)
    // silently returns the key itself, and the user reads it off the screen.
    if ((await exists(ENUM_FILE)) && (await exists(EXT_STRINGS))) {
      const enumText = await Deno.readTextFile(ENUM_FILE);
      const declared = [...enumText.matchAll(/case [A-Za-z]+ = "([a-z0-9_]+)"/g)].map((m) => m[1]);
      const present = new Set(await stringKeys(EXT_STRINGS));
      for (const key of declared) {
        if (!present.has(key)) {
          console.error(`UserFacingErrorKey.${key} has no string in ${EXT_STRINGS}`);
          failed = true;
        }
      }
    } else {
      console.error(`Missing ${ENUM_FILE} or ${EXT_STRINGS}`);
      failed = true;
    }

    if (failed) fail("localization key sets diverge");
  });
}

export async function secretScan(): Promise<void> {
  await step("Scanning for secrets (gitleaks)", async () => {
    const which = await run("which", { args: ["gitleaks"], allowFailure: true, capture: true });
    if (which.code !== 0) {
      fail("gitleaks not installed. Run `deno task init` (or `brew install gitleaks`)");
    }
    await run("gitleaks", { args: ["detect", "--source", ".", "--redact", "--no-banner"] });
  });
}
