# G-002: Hints - When To Use vs Omit

## Title

Provide accessibility hints only when they add missing action context.

## Problem Statement

Unnecessary hints add noise and slow navigation, while missing hints can leave custom interactions unclear.

## Rule

Add an accessibility hint only when the label, value, and role do not already communicate what action will occur.

## Rationale

Efficient screen reader navigation depends on concise output. Hints should clarify non-obvious behavior, not restate obvious semantics.

## How To Implement

### SwiftUI

- Use `.accessibilityHint(_:)` for controls with non-obvious consequences or gestures.
- Omit hints for standard controls where default semantics are clear.
- Keep hints short and action-oriented.
- Re-check hints when control behavior changes to avoid stale guidance.

### UIKit Interop Notes

- Set `accessibilityHint` on wrapped UIKit views only where needed.
- Avoid hint duplication when UIKit controls already provide enough context through label and traits.

## How To Test

### Accessibility Inspector

- Confirm hint exists only on controls that need extra action context.
- Confirm hint text does not duplicate label/value verbatim.

### VoiceOver Walkthrough

- Focus controls and verify announcements stay concise.
- Confirm controls with custom behavior include a useful hint.

### Optional XCUITest Hook

- Validate presence/absence of hints for high-risk custom controls through UI metadata checks where available.

## Do / Don't

- Do: add hints for custom gestures or destructive actions when intent is not obvious.
- Don't: add hints that merely repeat the label (for example, label "Save", hint "Saves item").

## Citations

- [APPLE-VIEW-ACCESSIBILITY] https://developer.apple.com/documentation/swiftui/view-accessibility
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
