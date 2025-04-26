## Craftify Project Overview

### Purpose
Craftify is an iOS application (iOS 16+) with a Share Extension for contextual text processing (translation, simplification, correction, explanation) via the OpenAI API. It allows users to quickly process text from any app without switching between services.

### Problem
Users spend time copying text between apps for translation, simplification, or correction. Craftify eliminates the need for these actions, speeding up the workflow.

### Solution
Implemented caching for Mint, DerivedData, and SwiftPM dependencies to speed up the pipeline.

### Goals and Objectives
- Seamless integration of text processing.
- Increased productivity and user convenience.
- Modular architecture with shared code via Swift Package (Common).
- Secure storage of the API key only in Keychain with Keychain Sharing.
- Unified logging.
- Flexible configuration of operations and languages.
- Mandatory requirement: all key user scenarios must be covered by end-to-end tests (E2E), including edge cases and negative scenarios.

### Target Audience
- Multilingual users.
- Students and professionals.
- Anyone who needs to quickly explain or simplify text.

### Success Criteria
- Average response time ≤ 3 s for short texts (up to 1000 characters).
- Share Extension size ≤ 20 MB.
- Test coverage ≥ 80%.
- All key user scenarios are covered by end-to-end tests (E2E).
- Ease and simplicity of use.
- Compliance with security and privacy requirements.