# macOS Track

Use this track for macOS apps and desktop UI paths that depend on AppKit or SwiftUI on macOS.

- Backlog: `docs/macos/guidelines/topic-backlog.md`
- Guidelines: `docs/macos/guidelines/`
- Shared standards: `docs/core/`

## Track Status

- Initial backlog scaffolding is in place.
- Guideline IDs `M-001` through `M-010` are prioritized for first-pass drafting.
- Guideline set `M-001` through `M-010` is drafted and ready for tier-validation review.

## Primary Risks In Scope

- Missing `NSAccessibility` role/value/action semantics for custom `NSView` content.
- Keyboard navigation order mismatches versus visual hierarchy.
- Window/dialog transitions that lose assistive focus context.
