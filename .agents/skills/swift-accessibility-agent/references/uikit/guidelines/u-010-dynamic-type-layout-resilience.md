# U-010: Dynamic Type and Layout Resilience

## Title

Support Dynamic Type at all content sizes without loss of meaning or function.

## Problem Statement

If text scales but layouts break, users with Larger Text settings face clipped content, hidden actions, and incomplete task flows.

## Rule

All user-facing text and interactive layouts must remain readable and operable across supported Dynamic Type sizes, including accessibility categories.

## Rationale

Text scaling is a core iOS accessibility behavior. Layout resilience is required so increased text size does not degrade access.

## How To Implement

### UIKit

- Use Dynamic Type-compatible fonts (`preferredFont` + text styles).
- Enable automatic content-size-category adjustments for text controls.
- Avoid fixed row heights and rigid constraints that clip text at large sizes.
- Validate cell reuse with long localized strings and large text sizes.

### SwiftUI Interop Notes

- Verify UIKit constraints do not clip hosted SwiftUI content at large sizes.
- Keep text-scaling behavior consistent across mixed UIKit/SwiftUI screens.

## How To Test

### Accessibility Inspector

- Review screens at large categories for clipping, truncation, and overlap.
- Verify tappable targets remain reachable after text expansion.

### VoiceOver Walkthrough

- Enable large text category and verify focus order still matches workflow.
- Confirm critical labels and actions remain discoverable.

### Optional XCUITest Hook

- Add smoke/snapshot checks for key screens at selected large content-size categories.

## Do / Don't

- Do: allow text to wrap and containers to expand naturally.
- Don't: lock essential text into fixed-height rows that truncate at accessibility sizes.

## Citations

- [APPLE-HIG-ACCESSIBILITY] https://developer.apple.com/design/human-interface-guidelines/accessibility
- [APPLE-AX-TESTING] https://developer.apple.com/documentation/accessibility/performing-accessibility-testing-for-your-app
- [ASC-ANL-OVERVIEW] https://developer.apple.com/help/app-store-connect/manage-app-accessibility/overview-of-accessibility-nutrition-labels/

## Quote Snippets (Optional)

- None included in this draft.

## Metadata

- Status: Accepted
- Last Reviewed: 2026-03-07
- Last Verified: 2026-03-07
- Platforms: iOS, iPadOS
- Confidence: Medium
