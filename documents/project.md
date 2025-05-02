## Craftify Project Overview

### Purpose
Craftify is an iOS application (iOS 16+) with a Share Extension for contextual text processing (translation, simplification, correction, explanation) via the OpenAI API. It allows you to quickly process text from any app without switching between services.

### Problem
Users waste time copying text between apps for translation, simplification, or correction. Craftify eliminates these steps, speeding up the workflow.

### Solution
- Introduced a result processing mode (resultMode) for operations: the result can be copied to the clipboard or displayed in a popup window (for Explain, for example).
- All operations except Explain copy the result to the clipboard; Explain displays the result directly in the extension window.
- Covered by unit, UI, and e2e tests.
- Mint, DerivedData, and SwiftPM caching for faster CI/CD.

### Goals and Objectives
- Seamless integration of text processing.
- Increased productivity and user convenience.
- Modular architecture with shared code via Swift Package (Common).
- Secure API key storage only in Keychain with Keychain Sharing support.
- Unified logging.
- Flexible configuration of operations and languages.
- All key user scenarios are covered by e2e tests, including edge cases and negative scenarios.

### Target Audience
- Multilingual users.
- Students and professionals.
- Anyone who needs to quickly explain or simplify text.

### Success Criteria
- Average response time ≤ 3s for short texts (up to 1000 characters).
- Share Extension size ≤ 20 MB.
- Test coverage ≥ 80%.
- All key scenarios are covered by e2e tests.
- Simplicity and ease of use.
- Compliance with security and privacy requirements.

### New Features
- Support for selecting a color for each operation from a palette.
- Operation color is saved and displayed on the main screen and in the Share Extension.
- Introduced result processing mode (clipboard/display) for operations.
- For Explain, the result is displayed in a scrollable popup window.
- Covered by unit, UI, and e2e tests.
- Share Extension can now be activated for both text and URLs (public.text, public.url) via NSExtensionActivationRule in project.yml (XcodeGen).
- Оба типа обрабатываются как обычный текст, приоритет у текста. Покрыто unit- и e2e-тестами.

## Problems Solved
- Added resultMode attribute for operations, implemented support for result display mode.
- Removed stylePreservationLevel property from the correct operation. Now the style is always preserved at maximum, the user cannot choose the style preservation level.
- UI and ViewModel updated: Stepper and related fields removed.
- All tests (unit, e2e) updated to match the new logic.
- Share Extension теперь поддерживает шаринг ссылок (public.url) и текста (public.text), оба типа обрабатываются как текст, приоритет у текста.