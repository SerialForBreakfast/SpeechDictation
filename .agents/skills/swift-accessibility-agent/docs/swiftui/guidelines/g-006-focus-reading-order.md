# G-006: Focus and Reading Order

## Title

Ensure accessibility focus order follows a logical, predictable reading sequence.

## Problem Statement

When focus jumps unpredictably or does not match screen structure, users lose context and cannot complete tasks efficiently.

## Rule

Accessibility focus order must follow a coherent content flow; use structural hierarchy first, and apply explicit sort priority only to correct true ordering issues.

## Rationale

VoiceOver and switch-based navigation rely on deterministic traversal order. Predictable order reduces cognitive load and prevents missed controls.

## How To Implement

### SwiftUI

- Build semantic order through view hierarchy and container structure before adding explicit priorities.
- Use `.accessibilitySortPriority(_:)` sparingly to resolve edge-case ordering conflicts.
- Preserve heading structure and section grouping to improve rotor and linear navigation.
- Re-validate order when introducing overlays, sheets, and async content insertion.

### UIKit Interop Notes

- Verify `UIHostingController` inside UIKit navigation/container stacks does not reorder elements unexpectedly.
- In representables, ensure UIKit subview ordering aligns with expected spoken traversal order.

## How To Test

### Accessibility Inspector

- Inspect traversal order and verify it matches expected content flow.
- Confirm no hidden/overlay elements are unexpectedly focusable before primary content.
- Confirm sort priorities are intentional and minimal.

### VoiceOver Walkthrough

- Swipe through each screen and verify top-level order matches user task flow.
- Open sheets/alerts and confirm focus enters modal content and returns correctly on dismiss.

### Optional XCUITest Hook

- Use screen-level smoke tests that assert key controls appear in expected interaction sequence.

## Do / Don't

- Do: model layout so natural hierarchy produces the right focus order.
- Don't: depend on widespread sort-priority overrides to patch structural ordering issues.

## Citations

- [APPLE-VIEW-ACCESSIBILITY] https://developer.apple.com/documentation/swiftui/view-accessibility
- [APPLE-SWIFTUI-ACCESSIBILITY] https://developer.apple.com/documentation/swiftui/accessibility
- [APPLE-WWDC23-SWIFTUI-UIKIT] https://developer.apple.com/videos/play/wwdc2023/10036/

## Quote Snippets (Optional)

- None included in this draft.

## Metadata

- Status: Accepted
- Last Reviewed: 2026-03-07
- Last Verified: 2026-03-07
- Platforms: iOS, iPadOS
- Confidence: Medium
