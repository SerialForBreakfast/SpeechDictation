# U-006: Focus and Reading Order

## Title

Ensure accessibility focus order follows a logical, predictable reading sequence.

## Problem Statement

When focus jumps unpredictably or does not match screen structure, users lose context and cannot complete tasks efficiently.

## Rule

Accessibility focus order must follow coherent task flow; use structural hierarchy first and explicit ordering overrides only for real edge cases.

## Rationale

VoiceOver and switch-based interaction rely on deterministic traversal order.

## How To Implement

### UIKit

- Build semantic order through view hierarchy and container composition.
- Avoid arbitrary subview reordering that breaks expected traversal.
- Ensure overlays and modals do not leave background elements focusable.
- Use explicit `accessibilityElements` ordering only when structure alone is insufficient.

### SwiftUI Interop Notes

- Validate focus order across UIKit containers hosting SwiftUI content.
- Re-test order after introducing representables, overlays, or async insertions.

## How To Test

### Accessibility Inspector

- Inspect traversal order and verify alignment with task flow.
- Confirm hidden/overlay elements are not focused before primary content.
- Confirm explicit ordering overrides are minimal and intentional.

### VoiceOver Walkthrough

- Swipe through each screen and verify sequence matches user workflow.
- Open/dismiss modal content and confirm focus handoff and restoration.

### Optional XCUITest Hook

- Add screen-level smoke tests asserting key controls appear in expected interaction sequence.

## Do / Don't

- Do: structure views so natural hierarchy produces the right order.
- Don't: patch structural ordering defects with widespread manual overrides.

## Citations

- [APPLE-AX-HUB] https://developer.apple.com/documentation/accessibility
- [APPLE-AX-TESTING] https://developer.apple.com/documentation/accessibility/performing-accessibility-testing-for-your-app
- [APPLE-WWDC23-SWIFTUI-UIKIT] https://developer.apple.com/videos/play/wwdc2023/10036/

## Quote Snippets (Optional)

- None included in this draft.

## Metadata

- Status: Accepted
- Last Reviewed: 2026-03-07
- Last Verified: 2026-03-07
- Platforms: iOS, iPadOS
- Confidence: Medium
