# Craftify – App Store Reviewer Documentation

## 1. App Overview

**Craftify** is an iOS application with a Share Extension for contextual text processing using an external LLM API (such as OpenAI). **To use the app, the user must provide their own LLM API key in the settings.** All text processing requests are securely sent to the external LLM provider for processing. The app allows users to perform operations such as translation, simplification, correction, explanation, and summarization of selected text from any app—directly or via the Share Extension.

- **App Name:** Craftify
- **Bundle ID:** *group.dev.korchasa.Craftify*
- **Platforms:** iOS (iPhone, iPad)
- **Supported Languages:** English, Russian (UI is fully localized)
- **App Group:** group.dev.korchasa.Craftify
- **Keychain Sharing:** group.dev.korchasa.Craftify

## 2. Key Features

- Contextual text processing via external LLM API (e.g., OpenAI) for translation, simplification, correction, explanation, and summarization
- User must provide their own LLM API key in the app settings
- Share Extension for processing text from any app
- Customizable operation list (add, edit, reorder, delete operations)
- Localized user interface and user-facing strings
- Settings screen with privacy options
- All user data and logs are stored securely in the App Group container

## 3. Technical Details

- **Architecture:** Modular (MainApp, ShareExtension, Common SPM module)
- **CI/CD:** Automated via GitHub Actions; all builds and tests are reproducible via CLI
- **Dependencies:** External LLM API (e.g., OpenAI), SwiftUI, New Relic SDK (for crash reporting in MainApp only)
- **Minimum iOS Version:** 16.0
- **App Group Storage:** Used for sharing data and logs between MainApp and Share Extension
- **Keychain Sharing:** Used for secure API key storage
- **LLM API Key:** Required. The user must enter their own LLM API key (e.g., OpenAI) in the app settings. The key is stored securely in the keychain and never shared.
- **External Requests:** All text processing requests are sent to the external LLM provider specified by the user's API key.

## 4. Privacy Policy

> **Data Collection:** Craftify does not collect or transmit any personal data to third parties. **However, all text processing requests are sent to the external LLM provider (such as OpenAI) specified by the user's API key, for the sole purpose of processing the user's request.** All logs are stored locally in the App Group container and are never shared externally. API keys are masked in logs and stored securely in the keychain.
>
> **Crash Reporting:** Crash reports are sent only from the MainApp via New Relic SDK. No crash data is sent from the Share Extension.
>
> **Permissions:** The app does not request access to contacts, photos, location, or other sensitive user data.
>
> **Privacy Policy URL:** <https://github.com/korchasa/Craftify/blob/main/documents/privacy-policy.md>

## 5. Contact Information

- **Developer:** Alexander Korchasa
- **Email:** <korchasa@gmail.com>
- **Support URL:** <https://github.com/korchasa/Craftify>

## 6. Testing Instructions

1. Install the app on a device running iOS 16.0 or later.
2. Launch Craftify MainApp. The home screen displays the list of available operations.
3. Open **Settings** and enter your LLM API key (e.g., OpenAI API Key). The app will not function without a valid key.
4. Tap **+** to add a new operation (e.g., Translate, Simplify).
5. Use the **Settings** button to access the settings screen where you can view privacy information.
6. To test the Share Extension:
   - Select any text in another app (e.g., Safari, Notes).
   - Tap **Share** and choose **Craftify** from the share sheet.
   - The extension will process the selected text using the chosen operation.
7. All user-facing strings are localized. To test localization, change the device language in iOS settings and relaunch the app.

> **Note:** No login or demo account is required. All features are available after entering a valid LLM API key.

## 7. App Store Reviewer Notes

- The user must provide their own LLM API key in the settings. All text processing requests are sent to the external LLM provider for processing.
- No in-app purchases or subscriptions are present.
- All user data remains on device except for text sent to the LLM provider for processing, as initiated by the user.
- App supports both light and dark mode.
- All user-facing text is localized and uses `NSLocalizedString` with an explicit bundle.
- App is fully functional on iPhone and iPad.
- The app does not use private APIs or require special entitlements.

## 8. Screenshots

See App Store Connect for full-resolution screenshots for all supported devices and languages.

![App Icon](icon.png)

## 9. Version History & Changelog

- **1.0.0** – Initial release. All core features implemented and tested.

## 10. Legal & Compliance

- All third-party libraries are used in compliance with their licenses.
- The app does not use or collect any protected health, financial, or sensitive personal data.
- The app complies with all App Store Review Guidelines as of April 2025.

## 11. Additional Notes

- For any questions or additional information, please contact the developer at the email above.
- All documentation is available in the `documents/` directory of the project repository.