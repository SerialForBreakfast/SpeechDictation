# G-005: Grouping and Containment

## Title

Group accessibility elements intentionally to match how users understand each UI concept.

## Problem Statement

Incorrect grouping creates noisy, repetitive announcements or hides actionable elements, making navigation slow and error-prone.

## Rule

Choose grouping behavior (`combine`, `contain`, `ignore`) based on user intent: combine elements that represent one concept, contain related interactive children, and ignore decorative noise.

## Rationale

Assistive technologies navigate the accessibility tree, not the visual layout. Grouping must reflect conceptual structure so users can move efficiently and understand context.

## How To Implement

### SwiftUI

- Use `.accessibilityElement(children: .combine)` for rows where multiple text fragments form one meaning.
- Use `.accessibilityElement(children: .contain)` when child controls must remain individually actionable.
- Use `.accessibilityElement(children: .ignore)` or `.accessibilityHidden(true)` for decorative-only content.
- Re-check grouping after layout refactors; visual changes often break semantic grouping.

### UIKit Interop Notes

- In UIKit containers, ensure child accessibility exposure is not flattened unexpectedly.
- In representables, verify container and child `isAccessibilityElement` behavior matches intended grouping.

## How To Test

### Accessibility Inspector

- Verify tree structure matches expected conceptual groups.
- Verify actionable children remain focusable when containment is required.
- Verify decorative descendants do not appear as separate focus targets.

### VoiceOver Walkthrough

- Swipe through grouped sections and confirm concise announcements for combined content.
- Confirm separately actionable controls remain individually reachable.

### Optional XCUITest Hook

- Use identifier-level assertions for expected child element presence/absence in grouped rows.

## Do / Don't

- Do: combine a title + subtitle row into one element when both describe one item.
- Don't: combine rows that contain buttons/toggles users must activate separately.

## Citations

- [APPLE-VIEW-ACCESSIBILITY] https://developer.apple.com/documentation/swiftui/view-accessibility
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
