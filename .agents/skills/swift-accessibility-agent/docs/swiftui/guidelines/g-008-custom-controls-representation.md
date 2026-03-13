# G-008: Custom Controls and Accessibility Representation

## Title

When building custom controls, provide a semantic accessibility representation equivalent to standard controls.

## Problem Statement

Custom UI patterns often look correct visually but announce as generic views, leaving users without role, state, or action context.

## Rule

Any custom interactive component must expose equivalent accessibility semantics (role, label, value, actions) to the native control it replaces.

## Rationale

Assistive technologies depend on semantic structure rather than visuals. Equivalent semantic representation preserves predictable interaction behavior.

## How To Implement

### SwiftUI

- Prefer native controls first; custom controls are a fallback.
- If using a custom control, explicitly provide label, value, traits/role, and actions.
- Use accessibility representation techniques to map complex visuals to clear semantic elements.
- Keep semantic behavior synchronized with custom visual state transitions.

### UIKit Interop Notes

- In UIKit-backed custom views, set `isAccessibilityElement`, `accessibilityLabel`, `accessibilityValue`, and traits explicitly.
- In representables, verify semantic fields update when SwiftUI bindings change.

## How To Test

### Accessibility Inspector

- Confirm custom controls are exposed as the intended semantic type, not generic containers.
- Confirm label/value/traits/actions are all present and consistent.

### VoiceOver Walkthrough

- Focus custom control and verify announcement matches expected role/state.
- Trigger interaction and confirm updated state and action feedback.

### Optional XCUITest Hook

- Assert critical custom control states via accessibility labels/values/identifiers.

## Do / Don't

- Do: model a custom stepper as an adjustable control with clear increment/decrement behavior.
- Don't: ship custom tappable views with only visual affordances and no semantic role.

## Citations

- [APPLE-SWIFTUI-ACCESSIBILITY] https://developer.apple.com/documentation/swiftui/accessibility
- [APPLE-CREATING-ACCESSIBLE-VIEWS] https://developer.apple.com/documentation/accessibility/enhancing-the-accessibility-of-your-swiftui-app
- [APPLE-WWDC23-SWIFTUI-UIKIT] https://developer.apple.com/videos/play/wwdc2023/10036/

## Quote Snippets (Optional)

- None included in this draft.

## Metadata

- Status: Accepted
- Last Reviewed: 2026-03-07
- Last Verified: 2026-03-07
- Platforms: iOS, iPadOS
- Confidence: Medium
