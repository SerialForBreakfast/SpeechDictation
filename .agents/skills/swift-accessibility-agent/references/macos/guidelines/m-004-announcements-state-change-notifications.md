# M-004: Announcements and State-Change Notifications in AppKit

## Title

Emit meaningful accessibility notifications when important AppKit state changes occur.

## Problem Statement

If state changes are visible but not announced, assistive-tech users may miss confirmations, errors, and dynamic updates needed to complete tasks.

## Rule

When macOS UI state changes affect user understanding or next action, update accessibility properties and emit appropriate accessibility notifications so assistive technologies receive current context.

## Rationale

Dynamic desktop UIs can change without focus movement. Notifications bridge that gap by synchronizing assistive-tech context with application state.

## How To Implement

### SwiftUI (macOS)

- Ensure state changes are reflected in labels/values bound to visible controls.
- Prefer native controls that automatically announce common state transitions.
- For custom components, provide explicit updated state semantics.

### UIKit/AppKit Interop Notes

- In custom `NSView` implementations, post accessibility notifications for significant content/state changes.
- Ensure notification timing aligns with UI update completion.
- Verify hosted SwiftUI/AppKit boundaries do not suppress expected state announcements.

## How To Test

### Accessibility Inspector

- Verify updated state appears in inspected accessibility properties after actions.
- Verify notifications correspond to meaningful user-visible transitions.

### VoiceOver Walkthrough

- Trigger success/error/loading state changes and confirm announcements communicate outcome.
- Confirm updates are neither missing nor excessively repetitive.

### Optional XCUITest Hook

- Add assertions for visible state text/value changes that correspond to announced events.

## Do / Don't

- Do: announce state changes that affect user decisions or workflow progression.
- Don't: rely on visual-only banners/status text for critical updates.

## Citations

- [APPLE-MACOS-NSACCESSIBILITY] https://developer.apple.com/documentation/appkit/nsaccessibility-swift.struct
- [APPLE-AX-HUB] https://developer.apple.com/documentation/accessibility
- [APPLE-AX-TESTING] https://developer.apple.com/documentation/accessibility/performing-accessibility-testing-for-your-app

## Quote Snippets (Optional)

- None included in this draft.

## Metadata

- Status: Draft
- Last Reviewed: 2026-03-07
- Last Verified: 2026-03-07
- Platforms: macOS
- Confidence: Medium
