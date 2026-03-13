# G-004: Traits and Roles

## Title

Expose correct roles and traits so assistive technologies announce elements accurately.

## Problem Statement

When roles and traits are missing or incorrect, users hear misleading announcements and cannot predict control behavior.

## Rule

Use native semantic controls whenever possible; when custom UI is unavoidable, explicitly set accessibility traits/roles to match actual behavior.

## Rationale

Roles and traits define how assistive technologies classify elements, which affects navigation mode, interaction expectations, and spoken context.

## How To Implement

### SwiftUI

- Prefer semantic controls (`Button`, `Toggle`, `Slider`, `NavigationLink`, etc.) over gesture-only generic views.
- Use `.accessibilityAddTraits(_:)` and `.accessibilityRemoveTraits(_:)` to align behavior where needed.
- Mark structural headings with heading semantics to improve rotor-based navigation.
- Ensure selectable, adjustable, and destructive states are represented consistently with control behavior.

### UIKit Interop Notes

- Set `accessibilityTraits` in wrapped UIKit controls when default traits are not accurate.
- Validate trait mapping when embedding SwiftUI in UIKit containers that may override element behavior.

## How To Test

### Accessibility Inspector

- Verify each interactive element has a role/trait aligned to behavior.
- Verify heading landmarks appear where section navigation is expected.
- Verify custom controls are not exposed as generic static text when interactive.

### VoiceOver Walkthrough

- Confirm spoken announcements include expected role/trait context (for example, button, selected state, adjustable behavior).
- Confirm rotor navigation discovers headings where intended.

### Optional XCUITest Hook

- Assert trait-related state changes indirectly through label/value/state output for key controls.

## Do / Don't

- Do: use native controls first and add traits only for semantic corrections.
- Don't: implement tappable `HStack`/`ZStack` controls without matching semantic role exposure.

## Citations

- [APPLE-VIEW-ACCESSIBILITY] https://developer.apple.com/documentation/swiftui/view-accessibility
- [APPLE-SWIFTUI-ACCESSIBILITY] https://developer.apple.com/documentation/swiftui/accessibility
- [APPLE-WWDC23-SWIFTUI-UIKIT] https://developer.apple.com/videos/play/wwdc2023/10036/

## Quote Snippets (Optional)

- None included in this draft.

## Metadata

- Status: Accepted
- Last Reviewed: 2026-03-07
- Last Verified: 2026-03-07
- Platforms: iOS, iPadOS
- Confidence: Medium
