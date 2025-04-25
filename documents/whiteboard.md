# Investigation: Share Extension not appearing in share sheet

## Restatement
User cannot see the Craftify Share Extension in the iOS share sheet after installing the app.

## Hypotheses
1. The Share Extension is not embedded correctly into the main app bundle.
2. The extension was not installed or enabled on the simulator/device.
3. NSExtension activation attributes in Info.plist are misconfigured (e.g., conflicting text vs. attachments rules).
4. The extension is present but disabled in the share sheet "More" list by default.

## Investigation Steps
1. Confirm the `.appex` is embedded under `MainApp.app/PlugIns` after building and installing the app.
2. Verify the extension bundle is installed on the simulator via `simctl`.
3. Inspect `src/ShareExtension/Config/Info.plist` for activation attributes and look for conflicts.
4. Manually test sharing text and attachments in the simulator to see if the extension appears in either scenario.
5. Check the share sheet "More" list to ensure the extension is enabled.

## Observations Pending
- Extension appears in pluginkit list but is filtered out of text-only share sheet.

## Next Actions
- Run CLI commands to inspect the embedded `.appex`.
- Review Info.plist activation configuration.
- Document observed outcomes against each hypothesis.
- Test sharing an image (or any attachment) to see if the extension appears when attachments are present.
- Update `src/ShareExtension/Config/Info.plist` to remove the attachments requirement (`NSExtensionActivationSupportsAttachmentsWithMinCount`) so the extension can appear in text-only shares.
