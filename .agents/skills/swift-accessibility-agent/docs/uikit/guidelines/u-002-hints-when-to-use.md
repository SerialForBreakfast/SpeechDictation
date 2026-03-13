# U-002: Hints - When To Use vs Omit

## Title

Provide accessibility hints only when they add missing action context.

## Problem Statement

Unnecessary hints add noise and slow navigation, while missing hints can leave custom interactions unclear.

## Rule

Add an accessibility hint only when label, value, and role do not already communicate what action will occur.

## Rationale

Efficient screen reader navigation depends on concise output. Hints should clarify non-obvious behavior, not restate obvious semantics.

## How To Implement

### UIKit

- Use `accessibilityHint` only for controls with non-obvious consequences.
- Omit hints for standard controls when semantics are already clear.
- Keep hints short and action-oriented.
- Re-check hints when control behavior changes to prevent stale guidance.

### SwiftUI Interop Notes

- In mixed stacks, avoid duplicate hints between UIKit wrappers and hosted SwiftUI content.
- Ensure hint ownership is clear for shared controls.

## How To Test

### Accessibility Inspector

- Confirm hints are present only where extra action context is needed.
- Confirm hint text does not duplicate label/value verbatim.

### VoiceOver Walkthrough

- Focus controls and verify announcements stay concise.
- Confirm custom behavior controls include useful hints.

### Optional XCUITest Hook

- Validate presence/absence of hints for selected high-risk controls where metadata is inspectable.

## Do / Don't

- Do: add hints for destructive actions when consequence is not obvious.
- Don't: repeat the label as the hint.

## Citations

- [APPLE-AX-HUB] https://developer.apple.com/documentation/accessibility
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
