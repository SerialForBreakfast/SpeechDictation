# G-013: Modal and Sheet Focus Containment

## Title

Contain focus within active modal context and restore focus predictably on dismissal.

## Problem Statement

If focus escapes active modals or returns unpredictably after dismissal, users lose context and can trigger unintended actions.

## Rule

When presenting sheets, alerts, or full-screen overlays, focus must move into the presented context, stay within relevant elements, and return to a logical anchor after dismissal.

## Rationale

Modal UI changes interaction scope. Assistive technology users need deterministic focus behavior to understand current context and complete tasks safely.

## How To Implement

### SwiftUI

- Present modal content with clear headings/labels that identify the new context.
- Ensure background controls are not inadvertently reachable while modal interaction is active.
- Provide explicit dismissal actions with clear labels.
- On dismissal, return focus to the control that triggered presentation (or nearest logical anchor).

### UIKit Interop Notes

- Validate `UIHostingController` presentations in UIKit stacks for focus handoff and restoration.
- Ensure UIKit presentation styles do not leave hidden background elements in the accessibility traversal path.

## How To Test

### Accessibility Inspector

- Verify active modal tree is reachable and prioritized over background content.
- Verify background elements are not focusable during modal interaction when they should be inactive.

### VoiceOver Walkthrough

- Present modal and confirm immediate focus lands on modal title/first actionable element.
- Dismiss modal and confirm focus returns to expected trigger/anchor element.

### Optional XCUITest Hook

- Add flow tests asserting modal entry/exit controls and post-dismiss anchor visibility.

## Do / Don't

- Do: announce modal context with a clear title and predictable primary action.
- Don't: allow focus to continue traversing background content while modal is active.

## Citations

- [APPLE-CREATING-ACCESSIBLE-VIEWS] https://developer.apple.com/documentation/accessibility/enhancing-the-accessibility-of-your-swiftui-app
- [APPLE-WWDC23-SWIFTUI-UIKIT] https://developer.apple.com/videos/play/wwdc2023/10036/
- [APPLE-AX-TESTING] https://developer.apple.com/documentation/accessibility/performing-accessibility-testing-for-your-app

## Quote Snippets (Optional)

- None included in this draft.

## Metadata

- Status: Accepted
- Last Reviewed: 2026-03-07
- Last Verified: 2026-03-07
- Platforms: iOS, iPadOS
- Confidence: Medium
