# Craftify Developer Manual

---

## Install
- `./run init`: install CLI tools (tuist, swiftlint, swiftformat, xcbeautify, swiftgen, periphery)

## Build
- `./run generate`: tuist, swiftgen
- `./run build`: build

## Test
- `./run check`: unit/UI tests, lint, format
- Coverage auto-checked in CI

## Lint/Format
- `./run lint`: lint
- `./run format`: format

## CI/CD
- All automated via GitHub Actions (`.github/workflows/ci.yml`)
- ShareExt size, coverage (≥80%) required
- Periphery in lint

## Deploy
- Release/publish: Fastlane
- Signing/provision: Fastlane match

## Timeout Test
- Only in ShareExtensionViewModel (30s, override in tests)
- ShareExtensionManager: only logic

## Logs
- `./run logs`: Unified Log (os_log, subsystem: Internal)
- Change period: `log show --predicate 'subsystem == "Internal"' --style syslog --last 2h`

## Manual TestFlight Upload via Xcode
1. **Prepare the build**
   - Open the `MainApp` target in Xcode.
   - Bump the *Marketing Version* or *Build* in **General ▸ Version / Build** as needed.
   - Select **Any iOS Device (arm64)** or a real device—not a simulator.

2. **Archive**
   - In the top menu choose **Product ▸ Archive**.
   - Wait until the **Organizer** window opens with the newly created archive.

3. **Validate & Upload**
   - In **Organizer ▸ Archives** select the latest archive.
   - Click **Distribute App** ➝ **App Store Connect** ➝ **Upload**.
   - Keep **Rebuild from bitcode** unchecked (Apple removed bitcode).
   - Confirm the correct *Distribution Certificate* and *Provisioning Profile*.
   - Follow the wizard until **Upload** begins; wait for the green *Upload Succeeded* message.

4. **Processing in App Store Connect**
   - Open https://appstoreconnect.apple.com ▸ **My Apps ▸ Craftify ▸ TestFlight ▸ Builds**.
   - The build appears after Apple finishes *Processing* (≈5-20 min).

5. **Publish to testers**
   - Select the processed build ➝ **Add Internal Testers** (immediate) **or** **Submit for Beta Review** for external testers.
   - Fill in compliance & export encryption questions if prompted.
   - Once approved, toggle the build *ON* for selected tester groups.

6. **Troubleshooting**
   - If the build never appears, check **App Store Connect ▸ Activity ▸ All Builds** for errors.
   - Common issues: outdated certificates, missing export compliance, or entitlements mismatch.

> This manual path is intended for quick, ad-hoc TestFlight updates. CI/CD with Fastlane remains the canonical flow for repeatable releases.

