# G-007: Accessibility Actions and Custom Actions

## Title

Expose non-obvious interactions through explicit accessibility actions.

## Problem Statement

When features rely on hidden gestures or multi-step touch interactions, assistive technology users may be unable to trigger key functionality.

## Rule

Any interaction that cannot be reliably discovered or performed through default semantic controls must provide an explicit accessibility action.

## Rationale

Custom actions provide a predictable command surface for VoiceOver and switch-based interaction, especially for gesture-heavy interfaces.

## How To Implement

### SwiftUI

- Use `.accessibilityAction(_:)` for single custom operations.
- Use `.accessibilityActions { ... }` for multiple contextual operations.
- Use `.accessibilityAdjustableAction(_:)` for increment/decrement style controls.
- Keep action names concise, task-focused, and distinct.

### UIKit Interop Notes

- Map equivalent operations to `UIAccessibilityCustomAction` for UIKit-backed controls.
- Ensure action handlers in representables are synchronized with SwiftUI state updates.

## How To Test

### Accessibility Inspector

- Verify action names are exposed on relevant elements.
- Verify no duplicate/ambiguous action names on the same element.

### VoiceOver Walkthrough

- Focus element, open actions rotor/menu, and confirm expected actions are present.
- Execute each action and confirm state/result changes are announced.

### Optional XCUITest Hook

- Validate resulting state changes for action-driven operations through labels/values.

## Do / Don't

- Do: expose swipe-only row actions as explicit accessibility actions.
- Don't: depend solely on custom gestures for critical operations.

## Citations

- [APPLE-VIEW-ACCESSIBILITY] https://developer.apple.com/documentation/swiftui/view-accessibility
- [APPLE-SWIFTUI-ACCESSIBILITY] https://developer.apple.com/documentation/swiftui/accessibility
- [APPLE-WWDC24-SWIFTUI] https://developer.apple.com/videos/play/wwdc2024/10073/

## Quote Snippets (Optional)

- None included in this draft.

## Metadata

- Status: Accepted
- Last Reviewed: 2026-03-07
- Last Verified: 2026-03-07
- Platforms: iOS, iPadOS
- Confidence: Medium
