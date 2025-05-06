# Craftify Project Overview

---

## Purpose
Craftify is an iOS application (iOS 16+) with a Share Extension for contextual text processing (translation, simplification, correction, explanation) via the OpenAI API. It enables users to process text from any app without switching between services.

## Problem Statement
Users waste time copying text between apps for translation, simplification, or correction. This manual process is inefficient and error-prone.

## Solution Overview
- Result processing mode (`resultMode`) for operations: results can be copied to the clipboard or displayed in a popup window (e.g., Explain operation).
- All operations except Explain copy the result to the clipboard; Explain displays the result directly in the extension window.
- Modular architecture with a shared Swift Package (Common).
- Secure API key storage in Keychain with Keychain Sharing.
- Unified logging and flexible configuration.
- Comprehensive test coverage (unit, UI, e2e).

## Goals and Objectives
- Seamless integration of text processing.
- Increased productivity and user convenience.
- Modular, maintainable architecture.
- Secure and privacy-compliant data handling.
- All key user scenarios covered by e2e tests, including edge and negative cases.

## Target Audience
- Multilingual users
- Students and professionals
- Anyone needing quick text explanation or simplification

## Success Criteria
- Average response time ≤ 3s for short texts (≤1000 characters)
- Share Extension size ≤ 20 MB
- Test coverage ≥ 80%
- All key scenarios covered by e2e tests
- Simplicity and ease of use
- Compliance with security and privacy requirements

## Key Features
- Color selection for each operation from a palette
- Operation color is saved and displayed in both the main app and Share Extension
- Result processing mode (clipboard/display) for operations
- Explain operation displays result in a scrollable popup window
- Share Extension supports both text and URLs (public.text, public.url) via NSExtensionActivationRule in project.yml (XcodeGen)
- Both types are processed as plain text, with priority given to text
- All features are covered by unit, UI, and e2e tests

## Solved Problems
- Added `resultMode` attribute for operations, supporting result display mode
- Removed `stylePreservationLevel` from the correct operation; style is always maximally preserved
- UI and ViewModel updated: Stepper and related fields removed
- All tests updated to match new logic
- Share Extension now supports sharing links (public.url) and text (public.text), both processed as text (priority: text)
- [See also: Implementation Details](implementation.md)

### URL Text Fetcher for SummarizeOperation
- SummarizeOperation can accept a URL; the system downloads HTML, extracts meaningful text from `<body>` using SwiftSoup, and summarizes it
- Only HTTPS URLs are supported (App Transport Security)
- Only visible `<body>` text is extracted; scripts/styles are ignored
- No manual copy-paste required for web content

## UI Requirements
- All screens must have a strictly white background (`Color.white`)
- System or gray backgrounds (including default List, Form, ScrollView, and safe area backgrounds) are not allowed
- Applies to all main and auxiliary screens, including Share Extension
- All user-facing surfaces must maintain a clean, white background for visual consistency and clarity

## References
- [Architecture](architecture.md)
- [Implementation](implementation.md)
- [File Structure](file_structure.md)
- [Developer Manual](developer-manual.md)
- [User Manual](user-manual.md)

## Migration to Tuist

The project is now fully managed by Tuist:
- All targets, dependencies, resources, and schemes are described in Project.swift and Workspace.swift.
- XcodeGen, project.yml, .xcodeproj, and .xcworkspace are removed.
- All builds and tests are performed via tuist and CLI scripts (see ./run).
- This ensures reproducible, DevOps-friendly, and CI/CD-compatible workflows.
- All configuration is file-based, no manual Xcode GUI work required.

## DevOps-friendly flow
- All project structure and configuration are described in code (Project.swift, Workspace.swift, configs).
- No manual steps: all builds, tests, and code generation are automated.
- Easy onboarding: just run ./run init and ./run generate.