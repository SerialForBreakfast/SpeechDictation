# U-014: Table, Collection, and Form Control Semantics

## Title

Use native control semantics and clear grouping in dense table, collection, and form interfaces.

## Problem Statement

Complex cells and form compositions often produce ambiguous announcements, hidden actions, and inefficient navigation.

## Rule

In tables, collections, and forms, prefer native controls and explicit row semantics so each item exposes clear label, value, role, and action behavior.

## Rationale

Dense screens magnify semantic errors. Consistent row/control semantics reduce navigation friction and improve task reliability.

## How To Implement

### UIKit

- Use standard UIKit controls in cells/forms for built-in semantics.
- Decide per row whether content should be combined or separately actionable.
- Expose contextual row actions through custom actions when needed.
- Reset reused cell accessibility state to avoid stale labels/values.

### SwiftUI Interop Notes

- Align UIKit cell semantics with SwiftUI row semantics in mixed screens.
- Verify embedded hosted views do not duplicate row announcements.

## How To Test

### Accessibility Inspector

- Check each row/control exposes expected role and current value.
- Check grouped rows do not hide required child actions.
- Check toggles/sliders expose adjustable/state semantics correctly.

### VoiceOver Walkthrough

- Traverse table/collection/form content and confirm concise announcements.
- Interact with stateful controls and confirm updated values are announced.

### Optional XCUITest Hook

- Assert representative row/control identifiers and state labels in key flows.

## Do / Don't

- Do: keep each row semantically focused on one primary task.
- Don't: pack multiple unrelated actions into one unlabeled cell.

## Citations

- [APPLE-AX-HUB] https://developer.apple.com/documentation/accessibility
- [APPLE-AX-TESTING] https://developer.apple.com/documentation/accessibility/performing-accessibility-testing-for-your-app
- [APPLE-WWDC23-AUDITS] https://developer.apple.com/videos/play/wwdc2023/10035/

## Quote Snippets (Optional)

- None included in this draft.

## Metadata

- Status: Accepted
- Last Reviewed: 2026-03-07
- Last Verified: 2026-03-07
- Platforms: iOS, iPadOS
- Confidence: Medium
