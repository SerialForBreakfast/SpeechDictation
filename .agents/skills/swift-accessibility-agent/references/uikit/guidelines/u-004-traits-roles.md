# U-004: Traits and Roles

## Title

Expose correct roles and traits so assistive technologies announce elements accurately.

## Problem Statement

When roles and traits are missing or incorrect, users hear misleading announcements and cannot predict control behavior.

## Rule

Use native semantic controls whenever possible; when custom UI is unavoidable, explicitly set accessibility traits/roles to match actual behavior.

## Rationale

Roles and traits define how assistive technologies classify elements and set interaction expectations.

## How To Implement

### UIKit

- Prefer semantic UIKit controls over gesture-only generic `UIView` interactions.
- Set `accessibilityTraits` to align announcements with actual behavior.
- Mark structural headings where section navigation is needed.
- Ensure selected/adjustable/destructive context is represented consistently.

### SwiftUI Interop Notes

- Validate trait mapping when UIKit hosts SwiftUI via `UIHostingController`.
- Ensure container-level behavior does not flatten child role semantics.

## How To Test

### Accessibility Inspector

- Verify each interactive element has correct role/trait.
- Verify heading landmarks appear where expected.
- Verify custom controls are not exposed as generic static text.

### VoiceOver Walkthrough

- Confirm announcements include expected role/trait context.
- Confirm heading navigation works for long content sections.

### Optional XCUITest Hook

- Assert trait-related behavior indirectly through state/label/value output for key controls.

## Do / Don't

- Do: use native controls first and add traits only for semantic correction.
- Don't: ship tappable container views without role exposure.

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
