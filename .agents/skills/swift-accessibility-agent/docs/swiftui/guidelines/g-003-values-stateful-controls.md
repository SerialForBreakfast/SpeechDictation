# G-003: Values for Stateful Controls and Readouts

## Title

Expose current state through accessibility values for controls and status readouts.

## Problem Statement

If state changes are visible but not announced semantically, assistive technology users cannot reliably determine current control status.

## Rule

Any UI element with meaningful state must provide an accurate accessibility value that updates with state changes.

## Rationale

State awareness is required for correct action decisions. Without value announcements, users may activate controls blindly or misinterpret current app state.

## How To Implement

### SwiftUI

- Use native controls first; many expose state semantics automatically.
- Add `.accessibilityValue(_:)` for custom stateful elements and readouts.
- Keep value text concise and user-focused (for example, "On", "75 percent", "3 selected").
- Ensure value updates are synchronized with visual state updates.

### UIKit Interop Notes

- Set `accessibilityValue` on UIKit-backed controls/readouts when SwiftUI wrappers do not provide it.
- In representables, update UIKit accessibility value whenever bound state changes.

## How To Test

### Accessibility Inspector

- Inspect stateful elements and verify value is present and current.
- Trigger state change and re-check value immediately after update.

### VoiceOver Walkthrough

- Focus stateful controls and confirm spoken output includes current value.
- Change state and confirm subsequent focus announces the new value.

### Optional XCUITest Hook

- Assert toggle/slider/value labels for representative controls.
- Add smoke assertions for critical state announcements where UI labels map deterministically.

## Do / Don't

- Do: expose "Selected"/"Not selected", numeric levels, or progress values when state matters.
- Don't: rely only on color, icon changes, or animation to communicate control state.

## Citations

- [APPLE-SWIFTUI-ACCESSIBILITY] https://developer.apple.com/documentation/swiftui/accessibility
- [APPLE-CREATING-ACCESSIBLE-VIEWS] https://developer.apple.com/documentation/accessibility/enhancing-the-accessibility-of-your-swiftui-app
- [APPLE-HIG-ACCESSIBILITY] https://developer.apple.com/design/human-interface-guidelines/accessibility

## Quote Snippets (Optional)

- None included in this draft.

## Metadata

- Status: Accepted
- Last Reviewed: 2026-03-07
- Last Verified: 2026-03-07
- Platforms: iOS, iPadOS
- Confidence: Medium
