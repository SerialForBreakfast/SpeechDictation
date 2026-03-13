# U-005: Grouping and Containment

## Title

Group accessibility elements intentionally to match how users understand each UI concept.

## Problem Statement

Incorrect grouping creates noisy announcements or hides actionable elements, making navigation slow and error-prone.

## Rule

Set accessibility grouping so combined content is concise, interactive children remain reachable when needed, and decorative noise is removed from traversal.

## Rationale

Assistive technologies navigate the accessibility tree, not the visual layout. Grouping must reflect conceptual structure.

## How To Implement

### UIKit

- Use container `isAccessibilityElement` and `accessibilityElements` behavior intentionally.
- Combine text fragments only when they represent one concept.
- Keep child controls separately reachable when they support distinct actions.
- Hide decorative views from accessibility traversal.

### SwiftUI Interop Notes

- In mixed containers, verify UIKit grouping does not flatten hosted SwiftUI children unexpectedly.
- Re-check grouping after list or cell refactors.

## How To Test

### Accessibility Inspector

- Verify tree structure matches expected conceptual groups.
- Verify actionable children remain focusable.
- Verify decorative descendants are not separate focus targets.

### VoiceOver Walkthrough

- Swipe grouped sections and confirm concise announcements.
- Confirm individually actionable controls remain reachable.

### Optional XCUITest Hook

- Use identifier-level assertions for expected child element presence/absence in grouped rows.

## Do / Don't

- Do: combine title and subtitle when they represent one row concept.
- Don't: combine rows that contain separately actionable controls.

## Citations

- [APPLE-AX-HUB] https://developer.apple.com/documentation/accessibility
- [APPLE-AX-TESTING] https://developer.apple.com/documentation/accessibility/performing-accessibility-testing-for-your-app
- [APPLE-WWDC23-AUDITS] https://developer.apple.com/videos/play/wwdc2023/10035/

## Quote Snippets (Optional)

- None included in this draft.

## Metadata

- Status: Accepted
- Last Reviewed: 2026-03-07
- Last Verified: 2026-03-07
- Platforms: iOS, iPadOS
- Confidence: Medium
