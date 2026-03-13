# G-001: Labels and Meaningful Names

## Title

Use clear, unique, user-centered accessibility labels for all meaningful controls and content.

## Problem Statement

When labels are missing, duplicated, or vague, assistive technology users cannot reliably identify controls or understand content purpose.

## Rule

Every meaningful interactive element and non-decorative content element must expose a clear accessibility label that reflects user intent, not implementation details.

## Rationale

Voice-driven and focus-driven navigation depend on labels as the primary semantic name. Clear labels reduce ambiguity and improve command reliability for VoiceOver and Voice Control.

## How To Implement

### SwiftUI

- Prefer native controls (`Button`, `Toggle`, `TextField`, etc.) because they provide baseline semantics.
- Use `.accessibilityLabel(_:)` when visible text is missing or insufficient.
- Mark decorative-only imagery as decorative so it is excluded from spoken output.
- Keep sibling labels distinct within the same context.

### UIKit Interop Notes

- Ensure wrapped UIKit views set `accessibilityLabel` and do not override SwiftUI-provided semantics accidentally.
- In representables, forward semantic naming from SwiftUI state into UIKit view properties.

## How To Test

### Accessibility Inspector

- Verify each meaningful control has a non-empty label.
- Verify labels are unique enough to disambiguate sibling controls.
- Verify decorative elements are not present as focusable items.

### VoiceOver Walkthrough

- Swipe through screen order and confirm each control is announced with a meaningful name.
- Confirm icon-only controls announce action intent (for example, "Delete message" instead of "Trash").

### Optional XCUITest Hook

- Assert presence by accessibility identifier where possible.
- Assert user-facing labels for high-risk controls using accessibility label assertions.

## Do / Don't

- Do: add explicit labels to icon-only buttons and non-text controls.
- Don't: use vague labels such as "Tap here", "Button", or repeated names that do not distinguish actions.

## Citations

- [APPLE-SWIFTUI-ACCESSIBILITY] https://developer.apple.com/documentation/swiftui/accessibility
- [APPLE-HIG-ACCESSIBILITY] https://developer.apple.com/design/human-interface-guidelines/accessibility
- [APPLE-AX-HUB] https://developer.apple.com/documentation/accessibility

## Quote Snippets (Optional)

- None included in this draft.

## Metadata

- Status: Accepted
- Last Reviewed: 2026-03-07
- Last Verified: 2026-03-07
- Platforms: iOS, iPadOS
- Confidence: Medium
