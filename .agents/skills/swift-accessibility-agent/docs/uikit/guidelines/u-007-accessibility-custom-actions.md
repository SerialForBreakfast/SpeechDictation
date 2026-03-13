# U-007: Accessibility Custom Actions

## Title

Expose non-obvious interactions through explicit accessibility custom actions.

## Problem Statement

When features depend on hidden gestures or touch-only row operations, assistive technology users may be unable to trigger key functionality.

## Rule

Any interaction that cannot be reliably discovered through default control semantics must provide explicit accessibility custom actions.

## Rationale

Custom actions provide a predictable interaction surface for VoiceOver and switch-based users.

## How To Implement

### UIKit

- Use `UIAccessibilityCustomAction` for contextual row operations and gesture-heavy behaviors.
- Keep action names concise, task-focused, and distinct.
- Ensure action handlers update UI state and semantics immediately.

### SwiftUI Interop Notes

- Ensure action ownership is not duplicated between UIKit containers and hosted SwiftUI rows.
- Re-check action menus when migrating rows between stacks.

## How To Test

### Accessibility Inspector

- Verify expected custom actions are exposed on relevant elements.
- Verify no duplicate/ambiguous action names on the same element.

### VoiceOver Walkthrough

- Focus element, open actions menu, confirm expected actions exist.
- Execute each action and verify result/state is announced.

### Optional XCUITest Hook

- Validate resulting state changes for action-driven operations via labels/values.

## Do / Don't

- Do: expose swipe-only table row actions through custom actions.
- Don't: depend solely on gestures for critical operations.

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
