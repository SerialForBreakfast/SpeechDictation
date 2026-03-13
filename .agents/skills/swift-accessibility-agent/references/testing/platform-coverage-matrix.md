# Platform Accessibility Coverage Matrix

Last updated: 2026-03-07

## Purpose

Provide a quick map of which guideline tracks and test scripts apply per platform/framework combination.

## Coverage Matrix

| Platform | Framework | Primary Backlog | Priority Test Scripts |
|---|---|---|---|
| iOS/iPadOS | SwiftUI | docs/swiftui/guidelines/topic-backlog.md | docs/testing/manual-test-scripts.md, docs/testing/inspector-audit-checklist.md |
| iOS/iPadOS | UIKit | docs/uikit/guidelines/topic-backlog.md | docs/testing/manual-test-scripts.md, docs/testing/inspector-audit-checklist.md |
| tvOS | SwiftUI | docs/tvos/guidelines/topic-backlog.md | docs/testing/tvos-manual-test-scripts.md, docs/testing/inspector-audit-checklist.md |
| tvOS | UIKit | docs/tvos/guidelines/topic-backlog.md | docs/testing/tvos-manual-test-scripts.md, docs/testing/inspector-audit-checklist.md |
| macOS | SwiftUI | docs/macos/guidelines/topic-backlog.md | docs/testing/macos-manual-test-scripts.md, docs/testing/inspector-audit-checklist.md |
| macOS | AppKit | docs/macos/guidelines/topic-backlog.md | docs/testing/macos-manual-test-scripts.md, docs/testing/inspector-audit-checklist.md |

## Notes

- Use `docs/testing/xcuitest-hooks.md` as automation support across all platforms.
- For interop-heavy surfaces, run both platform script and cross-boundary semantic checks.
