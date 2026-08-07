# Craftify Developer Manual

---

## Install
- `deno task init`: install CLI tools (tuist, swiftlint, swiftformat, xcbeautify, swiftgen, periphery)

## Build
- `deno task generate`: tuist, swiftgen
- `deno task dev`: build Debug, install on the simulator, tail logs
- `deno task prod`: the same in Release
- `deno task dist`: unsigned App Store archive (signed outside this repository)

## Test
- `deno task check`: the full gate — unit tests, lint, format, localization parity
- `deno task test [test-id]`: the suite alone, or one target/case
- Coverage auto-checked in CI

## Lint/Format
- `deno task lint`: SwiftLint (strict) + Periphery
- `deno task fmt`: SwiftFormat over the Swift sources, `deno fmt` over the task scripts

## CI/CD
- All automated via GitHub Actions (`.github/workflows/ci.yml`)
- ShareExt size, coverage (≥80%) required
- Periphery in lint

## Deploy
- This repository builds and checks the app. It does not sign or upload it.
- `deno task dist`: build an UNSIGNED archive at `build/Craftify.xcarchive`.
- Signing, packaging and upload to App Store Connect all happen outside this repository.
  The archive path is part of that contract, so do not move it.

## Timeout Test
- Only in ShareExtensionViewModel (30s, override in tests)
- ShareExtensionManager: only logic

## Logs
- `deno task logs`: Unified Log (os_log, subsystem: Internal)
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

> This manual path is intended for quick, ad-hoc TestFlight updates, and it signs the build on this machine. The regular flow is the unsigned archive from `deno task dist`, which is signed and uploaded outside this repository.

