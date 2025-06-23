# Craftify Project Overview

---

## Purpose
- iOS app (iOS 16+) + Share Extension for contextual text processing (translate, simplify, correct, explain) via LLM API
- Process text from any app, no switching

## Problem
- Manual copy-paste for text processing is slow, error-prone

## Solution
- `resultMode`: clipboard/display for operations
- All ops except Explain → clipboard; Explain → popup
- Modular: shared SwiftPM module
- Secure API key in Keychain (sharing enabled)
- Unified logging, flexible config
- Full test coverage

## Goals
- Seamless text processing
- ↑ Productivity, convenience
- Modular, maintainable
- Secure, privacy-compliant
- All user scenarios tested (incl. edge/negative)

## Audience
- Multilingual users
- Students, professionals
- Anyone needing quick text explanation/simplification

## Success
- Avg. response ≤3s (≤1000 chars)
- ShareExt ≤20MB
- Test coverage ≥80%
- All key scenarios tested
- Simple, easy to use
- Security/privacy compliant

## Features
- Color selection per operation
- Color shown in app & ShareExt
- `resultMode` per op
- Explain → popup
- ShareExt: text & URL (priority: text)
- All features tested

## Solved
- `resultMode` added
- `stylePreservationLevel` removed
- UI/ViewModel: Stepper, fields removed
- Tests updated
- ShareExt: supports text/URL
- Refactored: removed dead code, simplified DI, updated docs

## SummarizeOperation URL Fetcher
- Accepts URL, downloads HTML, extracts <body> text (SwiftSoup), summarizes
- Only HTTPS, visible <body> text


## References
- [Architecture](architecture.md)
- [Implementation](implementation.md)
- [File Structure](file_structure.md)
- [Developer Manual](developer-manual.md)
- [User Manual](user-manual.md)

## Tuist Migration
- All config in Project.swift, Workspace.swift
- XcodeGen, .xcodeproj, .xcworkspace removed
- All builds/tests via tuist, CLI
- Reproducible, DevOps/CI/CD-friendly

## DevOps
- All config/code-based
- No manual steps
- Onboarding: `./run init && ./run generate`

## AppSettingsManager
- Centralized settings (incl. language)
- Ops always use current language
- No duplication in params
- All changes logged
- All tests pass, docs updated

## Use Cases
- Users: quick language/interface change
- Devs: centralized settings, transparent logging

## Metrics
- Ops use only current language
- No param duplication
- All tests/checks pass
- Docs reflect current state

## State
- Error handling: UserFacingError, localized, actionable
- Alert logic improved
- Logs: English only
- Tests: error/timeout/race conditions covered
- Refactored errors
- Stable, all tests pass, docs up to date