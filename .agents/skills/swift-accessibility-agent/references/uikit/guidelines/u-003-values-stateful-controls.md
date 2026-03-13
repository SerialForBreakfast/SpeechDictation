# U-003: Values for Stateful Controls and Readouts

## Title

Expose current state through accessibility values for controls and status readouts.

## Problem Statement

If state changes are visible but not announced semantically, assistive technology users cannot reliably determine current control status.

## Rule

Any UI element with meaningful state must provide an accurate accessibility value that updates with state changes.

## Rationale

State awareness is required for correct action decisions. Without value announcements, users may misinterpret current app state.

## How To Implement

### UIKit

- Use native controls first, then add `accessibilityValue` for custom stateful elements.
- Keep value text concise and user-focused (for example, "On", "75 percent").
- Ensure value updates are synchronized with visual state changes.
- For reusable cells/views, clear stale values during reuse.

### SwiftUI Interop Notes

- In mixed screens, confirm UIKit values and SwiftUI values do not conflict for equivalent controls.
- Validate state forwarding across representable boundaries.

## How To Test

### Accessibility Inspector

- Inspect stateful elements and verify value is present and current.
- Trigger state change and re-check value immediately.

### VoiceOver Walkthrough

- Focus stateful controls and confirm spoken output includes current value.
- Change state and confirm subsequent focus announces updated value.

### Optional XCUITest Hook

- Assert representative toggle/slider/value state labels after interaction.

## Do / Don't

- Do: expose selected/not-selected, progress, or numeric values where state matters.
- Don't: rely only on color or animation to communicate state.

## Citations

- [APPLE-AX-HUB] https://developer.apple.com/documentation/accessibility
- [APPLE-HIG-ACCESSIBILITY] https://developer.apple.com/design/human-interface-guidelines/accessibility
- [APPLE-AX-TESTING] https://developer.apple.com/documentation/accessibility/performing-accessibility-testing-for-your-app

## Quote Snippets (Optional)

- None included in this draft.

## Metadata

- Status: Accepted
- Last Reviewed: 2026-03-07
- Last Verified: 2026-03-07
- Platforms: iOS, iPadOS
- Confidence: Medium
