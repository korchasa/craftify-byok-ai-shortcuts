/** `deno task l10n` — localization key parity on its own, without the rest of the gate. */

import { checkLocalization } from "./scans.ts";

await checkLocalization();
