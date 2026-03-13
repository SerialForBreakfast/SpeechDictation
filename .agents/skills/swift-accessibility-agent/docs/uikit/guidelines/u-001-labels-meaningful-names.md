# U-001: Labels and Meaningful Names

## Title

Use clear, unique, user-centered accessibility labels for all meaningful controls and content.

## Problem Statement

When labels are missing, duplicated, or vague, assistive technology users cannot reliably identify controls or understand content purpose.

## Rule

Every meaningful interactive element and non-decorative content element must expose a clear accessibility label that reflects user intent, not implementation details.

## Rationale

VoiceOver and Voice Control depend on labels as primary semantic names. Clear labels reduce ambiguity and improve command reliability.

## How To Implement

### UIKit

- Prefer semantic controls (`UIButton`, `UISwitch`, `UITextField`, etc.) over gesture-only generic views.
- Set `accessibilityLabel` when visible text is missing or insufficient.
- Mark decorative-only imagery as non-accessible.
- Keep sibling control labels distinct within the same context.

### SwiftUI Interop Notes

- Ensure `UIHostingController` container logic does not override UIKit labels unintentionally.
- Keep semantic naming aligned between UIKit parents and hosted SwiftUI children.

## How To Test

### Accessibility Inspector

- Verify each meaningful control has a non-empty label.
- Verify labels disambiguate sibling controls.
- Verify decorative-only elements are not focusable.

### VoiceOver Walkthrough

- Swipe through screen order and confirm each control is announced with a meaningful name.
- Confirm icon-only controls announce user intent (for example, "Delete message").

### Optional XCUITest Hook

- Assert critical controls exist via stable identifiers.
- Assert high-risk control labels for user-critical flows.

## Do / Don't

- Do: add explicit labels to icon-only buttons and custom icon controls.
- Don't: use vague or repeated labels that do not distinguish actions.

## Citations

- [APPLE-AX-HUB] https://developer.apple.com/documentation/accessibility
- [APPLE-HIG-ACCESSIBILITY] https://developer.apple.com/design/human-interface-guidelines/accessibility
- [APPLE-WWDC23-SWIFTUI-UIKIT] https://developer.apple.com/videos/play/wwdc2023/10036/

## Quote Snippets (Optional)

- None included in this draft.

## Metadata

- Status: Accepted
- Last Reviewed: 2026-03-07
- Last Verified: 2026-03-07
- Platforms: iOS, iPadOS
- Confidence: Medium
