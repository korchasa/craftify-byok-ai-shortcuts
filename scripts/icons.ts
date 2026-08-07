/**
 * `deno task icons` — render the app icons from the committed SVG sources.
 *
 * Runs inside Alpine via Docker so the rasteriser version is fixed: rsvg-convert
 * from Homebrew renders gradients and strokes slightly differently between
 * machines, and an icon that shifts per developer is an icon nobody can review.
 */

import { exists, fail, run, section } from "./lib.ts";
import { step } from "./config.ts";

const SRC = "documents/icon.svg";

if (!(await exists(SRC))) fail(`Source SVG not found at ${SRC}`);

const docker = await run("which", { args: ["docker"], allowFailure: true, capture: true });
if (docker.code !== 0) fail("Docker CLI is required but not found. Install Docker Desktop first.");

// Rendered in the container: every AppIcon.appiconset entry named by its
// Contents.json, at size × scale, plus the iOS 26 Icon Composer glyph. That
// glyph PNG is only a white alpha mask — the per-appearance colour lives in
// AppIcon.icon/icon.json fill-specializations.
const SCRIPT = `
apk add --no-cache librsvg rsvg-convert jq python3 > /dev/null
SRC="${SRC}"
for json in src/*/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json; do
  dest=$(dirname "$json")
  if [ ! -f "$json" ]; then
    echo "Skipping $dest, no Contents.json"
    continue
  fi
  echo "→ Processing $dest"
  jq -c ".images[] | select(.filename != null)" "$json" | while read -r entry; do
    filename=$(echo "$entry" | jq -r ".filename")
    size=$(echo "$entry" | jq -r ".size" | cut -d"x" -f1)
    scale=$(echo "$entry" | jq -r ".scale" | tr -d "x")
    px=$(python3 -c "print(int(round(float('$size') * int('$scale'))))")
    rsvg-convert -w "$px" -h "$px" "$SRC" -o "$dest/$filename"
  done
done
GLYPH_SRC="documents/icon-glyph.svg"
GLYPH_DEST="src/MainApp/Resources/AppIcon.icon/Assets/glyph.png"
if [ -f "$GLYPH_SRC" ] && [ -d "$(dirname "$GLYPH_DEST")" ]; then
  echo "→ Rendering Icon Composer glyph $GLYPH_DEST"
  rsvg-convert -w 1024 -h 1024 "$GLYPH_SRC" -o "$GLYPH_DEST"
fi
`;

await step("Generating app icons via Docker", async () => {
  await run("docker", {
    args: [
      "run",
      "--rm",
      "-v",
      `${Deno.cwd()}:/work`,
      "-w",
      "/work",
      "alpine:3.21",
      "sh",
      "-euxo",
      "pipefail",
      "-c",
      SCRIPT,
    ],
  });
});

section("App icons regenerated (Docker)");
