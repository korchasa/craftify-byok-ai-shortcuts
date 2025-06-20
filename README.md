# Craftify

Craftify — iOS application with Share Extension for contextual text processing via multiple Large Language Models (OpenAI GPT-4o, Anthropic Claude, …).

## Installation and Launch

1. Clone the repository:
```sh
git clone <repo-url>
cd Craftify
```
2. Install all necessary CLI tools:
```sh
./run init
```
This will install via Homebrew: swiftlint, swiftformat, xcbeautify, swiftgen.
3. Generate the project:
```sh
./run generate
```
4. Build and run the project:
```sh
./run sim
```
5. To run checks:
```sh
./run check
```

## Main Commands
- `./run init` — install all CLI tools
- `./run sim` — build and run in simulator
- `./run check` — run all checks
- `./run clean` — clean build artifacts
- `./run logs` — view logs

## CI/CD
- All checks and builds are automated via GitHub Actions (`.github/workflows/ci.yml`)
- Checking Share Extension size and test coverage ≥ 80% are mandatory for successful build

## Architecture
- Modules: MainApp, ShareExtension, Common (SPM)
- App Group: `group.dev.korchasa.Craftify`
- Shared Keychain: `group.dev.korchasa.Craftify`

## Documentation
- Detailed documentation is located in the `documents/` directory

> After completing step 2, all stub files and stub tests are removed. The project fully complies with linter requirements and is ready for Common implementation.

## Tuist

The project is fully managed by Tuist:
- All targets, dependencies, resources, and schemes are described in Project.swift and Workspace.swift.
- XcodeGen, project.yml, .xcodeproj, and .xcworkspace are removed (replaced by Tuist manifests).
- All builds and tests are run via tuist and CLI scripts (see ./run).
- This ensures reproducible, DevOps-friendly, and CI/CD-compatible workflows.

## DevOps-friendly Process
- The entire project structure and configuration are described in code (Project.swift, Workspace.swift, configs).
- No manual steps: all builds, tests, and code generation are automated.
- Easy project onboarding: just run ./run init and ./run generate.

## Operations

### Translate (`translate`)
File: [TranslateOperation.swift](src/Common/Sources/Models/TranslateOperation.swift)

• Supported input: **text only**
• Parameters: `targetLanguage` – ISO-639-1 code of the desired language
• Result mode: **Clipboard** (copies translated text)
• Description: Translates input text to the target language, preserving meaning, tone, and formatting (Markdown/HTML).

### Simplify (`simplify`)
File: [SimplifyOperation.swift](src/Common/Sources/Models/SimplifyOperation.swift)

• Supported input: **text only**
• Parameters: —
• Result mode: **Clipboard**
• Description: Rewrites text using simpler vocabulary and structure, preserving formatting.

### Correct (`correct`)
File: [CorrectOperation.swift](src/Common/Sources/Models/CorrectOperation.swift)

• Supported input: **text only**
• Parameters: —
• Result mode: **Clipboard**
• Description: Corrects spelling, grammar, and punctuation errors, considering the original language and formatting.

### Explain (`explain`)
File: [ExplainOperation.swift](src/Common/Sources/Models/ExplainOperation.swift)

• Supported input: **text only**
• Parameters: —
• Result mode: **Display** (shows explanation in a popup)
• Description: Provides a clear explanation of a concept in the current interface language.

### Summarize (`summarize`)
File: [SummarizeOperation.swift](src/Common/Sources/Models/SummarizeOperation.swift)

• Supported input: **text or URL**
• Parameters: `length` – length limit (e.g., "≤ 200 words")
• Result mode: **Display**
• Description: Generates a brief summary covering all key points. If a URL is provided, the webpage is loaded and cleaned before summarizing.

**Key rules:**
- Default `resultMode` is `clipboard`; Explain and Summarize override it to `display`.
- Maximum input length: 5000 characters (controlled in Share Extension).
- URL input is accepted **only** by Summarize. Other operations show an error to the user if URL is received.
- All operations consider the current app language via `AppSettingsManager`.

## TestFlight Release
- https://appstoreconnect.apple.com/apps/6745511563/distribution