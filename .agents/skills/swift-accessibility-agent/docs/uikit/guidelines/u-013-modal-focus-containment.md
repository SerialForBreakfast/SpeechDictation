# U-013: Modal Focus Containment

## Title

Contain focus within active modal context and restore focus predictably on dismissal.

## Problem Statement

If focus escapes active modals or returns unpredictably after dismissal, users lose context and can trigger unintended actions.

## Rule

When presenting sheets, alerts, or overlays, focus must move into presented content, stay within relevant modal elements, and return to a logical anchor on dismissal.

## Rationale

Modal presentation changes interaction scope; deterministic focus behavior is required for safe, efficient task completion.

## How To Implement

### UIKit

- Ensure modal context includes a clear heading/title and primary action.
- Prevent inactive background content from remaining in traversal.
- Provide explicit dismissal actions with clear labels.
- Restore focus to launch trigger or nearest logical anchor on dismissal.

### SwiftUI Interop Notes

- Validate `UIHostingController` modals for focus handoff and restoration.
- Confirm mixed presentation styles do not leak background focus targets.

## How To Test

### Accessibility Inspector

- Verify modal tree is reachable and prioritized over background content.
- Verify inactive background elements are not focusable.

### VoiceOver Walkthrough

- Present modal and confirm focus lands on modal title or first primary action.
- Dismiss modal and confirm focus returns to expected anchor.

### Optional XCUITest Hook

- Add flow tests asserting modal entry/exit controls and post-dismiss anchor presence.

## Do / Don't

- Do: announce modal context with a clear title and predictable action.
- Don't: allow focus to traverse background controls while modal is active.

## Citations

- [APPLE-AX-TESTING] https://developer.apple.com/documentation/accessibility/performing-accessibility-testing-for-your-app
- [APPLE-HIG-ACCESSIBILITY] https://developer.apple.com/design/human-interface-guidelines/accessibility
- [APPLE-WWDC23-SWIFTUI-UIKIT] https://developer.apple.com/videos/play/wwdc2023/10036/

## Quote Snippets (Optional)

- None included in this draft.

## Metadata

- Status: Accepted
- Last Reviewed: 2026-03-07
- Last Verified: 2026-03-07
- Platforms: iOS, iPadOS
- Confidence: Medium
