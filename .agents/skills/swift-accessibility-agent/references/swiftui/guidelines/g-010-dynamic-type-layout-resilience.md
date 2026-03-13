# G-010: Dynamic Type and Layout Resilience

## Title

Support Dynamic Type at all content sizes without loss of meaning or function.

## Problem Statement

If text scales but layouts break, users with Larger Text settings face clipped content, hidden actions, and incomplete task flows.

## Rule

All user-facing text and interactive layouts must remain readable and operable across supported Dynamic Type sizes, including accessibility categories.

## Rationale

Text scaling is a core accessibility behavior on iOS. Layout resilience is required so increased text size does not degrade information access or action completion.

## How To Implement

### SwiftUI

- Use text styles (`.font(.body)`, `.headline`, etc.) and avoid fixed font sizes for primary content.
- Prefer adaptive layout containers that can wrap/reflow (`VStack`, flexible frames, multiline text).
- Avoid hard height/width constraints that clip text at large categories.
- Test controls with longer localized strings and larger categories together.

### UIKit Interop Notes

- Ensure UIKit views in representables use Dynamic Type-compatible fonts and adjust for content size category changes.
- Validate mixed SwiftUI/UIKit screens for clipping where UIKit constraints are rigid.

## How To Test

### Accessibility Inspector

- Review text and controls at large categories for clipping/truncation.
- Verify tappable targets remain reachable after text expansion.

### VoiceOver Walkthrough

- Enable a large text category and confirm reading/focus order still matches task flow.
- Confirm all critical labels and actions remain discoverable.

### Optional XCUITest Hook

- Add snapshot/smoke tests for key screens at selected large content-size categories.

## Do / Don't

- Do: allow text to wrap and containers to expand naturally.
- Don't: lock essential text into fixed-height rows that truncate at accessibility sizes.

## Citations

- [APPLE-HIG-ACCESSIBILITY] https://developer.apple.com/design/human-interface-guidelines/accessibility
- [APPLE-CREATING-ACCESSIBLE-VIEWS] https://developer.apple.com/documentation/accessibility/enhancing-the-accessibility-of-your-swiftui-app
- [APPLE-AX-TESTING] https://developer.apple.com/documentation/accessibility/performing-accessibility-testing-for-your-app

## Quote Snippets (Optional)

- None included in this draft.

## Metadata

- Status: Accepted
- Last Reviewed: 2026-03-07
- Last Verified: 2026-03-07
- Platforms: iOS, iPadOS
- Confidence: Medium
