# G-014: Lists, Forms, Toggles, Sliders, and Complex Rows

## Title

Use native control semantics and clear grouping in dense list/form interfaces.

## Problem Statement

Complex rows and form compositions often produce ambiguous announcements, hidden actions, and inefficient navigation.

## Rule

In lists and forms, prefer native controls and explicit row semantics so each item exposes clear label, value, role, and action behavior.

## Rationale

Dense screens magnify semantic errors. Consistent row/control semantics reduce navigation friction and improve task completion reliability.

## How To Implement

### SwiftUI

- Use `List`, `Form`, `Toggle`, `Slider`, and other native controls for built-in semantics.
- For complex rows, decide whether row content should be combined or kept as separate actionable children.
- Ensure row-level swipe/secondary actions are available through accessibility actions when needed.
- Keep value/state announcements accurate for toggles, sliders, and selection rows.

### UIKit Interop Notes

- For UIKit-backed table/collection content, align cell accessibility structure with SwiftUI row semantics.
- Verify reusable cells do not leak stale labels/values across reused content.

## How To Test

### Accessibility Inspector

- Check each row/control exposes expected role and current value.
- Check grouped rows do not hide required child actions.
- Check sliders/toggles expose adjustable/state semantics correctly.

### VoiceOver Walkthrough

- Traverse list/form top-to-bottom and confirm row announcements are concise and unambiguous.
- Interact with toggles/sliders and confirm updated values are announced.

### Optional XCUITest Hook

- Assert representative row/control identifiers and state labels in key form flows.

## Do / Don't

- Do: keep each form row semantically focused on one primary task.
- Don't: pack multiple unrelated interactive targets into one unlabeled row.

## Citations

- [APPLE-SWIFTUI-ACCESSIBILITY] https://developer.apple.com/documentation/swiftui/accessibility
- [APPLE-CREATING-ACCESSIBLE-VIEWS] https://developer.apple.com/documentation/accessibility/enhancing-the-accessibility-of-your-swiftui-app
- [APPLE-WWDC24-SWIFTUI] https://developer.apple.com/videos/play/wwdc2024/10073/

## Quote Snippets (Optional)

- None included in this draft.

## Metadata

- Status: Accepted
- Last Reviewed: 2026-03-07
- Last Verified: 2026-03-07
- Platforms: iOS, iPadOS
- Confidence: Medium
