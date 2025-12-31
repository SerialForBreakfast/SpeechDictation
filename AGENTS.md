# Repository Guidelines

## Project Structure & Module Organization
- `SpeechDictation/` holds the app source (Swift/SwiftUI). Key areas: `Services/`, `Speech/`, `Models/`, `UI/`.
- `SpeechDictationTests/` contains unit tests; `SpeechDictationUITests/` contains UI automation tests.
- `utility/` provides build/test automation scripts; outputs land in `build/`.
- `memlog/` and `Research/` store project docs and ADRs.

## Build, Test, and Development Commands
- `./utility/build_and_test.sh` runs a full simulator build with reporting in `build/reports/`.
- `./utility/build_and_test.sh --clean --enableUITests` performs a clean build plus unit and UI tests.
- `./utility/quick_iterate.sh` runs a fast development loop (UI tests off by default).
- Open the project with `open SpeechDictation.xcodeproj` for Xcode builds and debugging.

## Coding Style & Naming Conventions
- Use Swift 4-space indentation and standard Swift naming (UpperCamelCase for types, lowerCamelCase for members).
- SwiftUI view files should match their type names (for example, `SecureRecordingsView.swift`).
- SwiftLint is configured via `.swiftlint.yml`; note the “no emoji” custom rules and line length limits.
- To install or validate linting, use `./utility/setup_linting.sh` and `swiftlint lint --config .swiftlint.yml`.

## Testing Guidelines
- Tests use XCTest. Add unit tests under `SpeechDictationTests/` and UI tests under `SpeechDictationUITests/`.
- Name test classes `*Tests` and test methods `test*`.
- Run unit tests with `./utility/build_and_test.sh` and include UI coverage with `--enableUITests`.

## Commit & Pull Request Guidelines
- Recent commits use short, imperative summaries (for example, “Fix …”, “Add …”). Keep subjects concise.
- PRs should include: a brief summary, test command(s) run, and screenshots or screen recordings for UI changes.
- Link related issues if available, and call out any new permissions or data-handling behavior.

## Configuration & Security Notes
- The app requires microphone and speech recognition permissions; mention changes that affect privacy prompts.
- Build artifacts are stored in `build/`; avoid committing generated output.
