# M-010: macOS Accessibility Testing Workflow (Inspector + VoiceOver + Keyboard)

## Title

Run a repeatable macOS accessibility test workflow combining Inspector checks, VoiceOver walkthroughs, and keyboard-only traversal.

## Problem Statement

Without a consistent verification workflow, accessibility regressions in semantics, focus order, and keyboard operability are discovered late or missed entirely.

## Rule

Every significant macOS UI change must pass a three-part accessibility workflow: Accessibility Inspector audit, VoiceOver interaction walkthrough, and keyboard-only task traversal for critical flows.

## Rationale

No single tool validates all accessibility dimensions. Combined manual and tool-assisted checks provide enforceable, practical coverage.

## How To Implement

### SwiftUI (macOS)

- Define screen-level test paths before implementation to ensure verifiable acceptance criteria.
- Use stable accessibility identifiers on high-risk controls to support repeatable checks.
- Include keyboard-only completion criteria for each critical task flow.

### UIKit/AppKit Interop Notes

- For AppKit/custom views, include explicit checks for `NSAccessibility` role/value/action exposure.
- Verify SwiftUI-AppKit hosting boundaries do not alter expected focus/announcement behavior.
- Add regression checks for modal/window focus restoration after open/close transitions.

## How To Test

### Accessibility Inspector

- Inspect each changed screen for role/label/value/action correctness.
- Confirm non-interactive visual elements are not incorrectly focusable.
- Confirm hierarchy/grouping reflects expected navigation structure.

### VoiceOver Walkthrough

- Traverse top-priority task flows and confirm announcement clarity and order.
- Validate modal/window transitions keep focus context and return to logical anchors.
- Validate state changes announce updated context for controls and statuses.

### Optional XCUITest Hook

- Run smoke assertions for control presence, state updates, and modal open/close anchors.
- Use these hooks as regression guardrails, not a replacement for manual assistive-tech validation.

## Do / Don't

- Do: require Inspector + VoiceOver + keyboard evidence before marking a macOS accessibility-sensitive PR complete.
- Don't: treat passing XCUITest checks alone as accessibility sign-off.

## Citations

- [APPLE-AX-INSPECTOR] https://developer.apple.com/documentation/accessibility/accessibility-inspector
- [APPLE-AX-TESTING] https://developer.apple.com/documentation/accessibility/performing-accessibility-testing-for-your-app
- [APPLE-WWDC25-MAC-ACCESSIBILITY] https://developer.apple.com/videos/play/wwdc2025/229/

## Quote Snippets (Optional)

- None included in this draft.

## Metadata

- Status: Draft
- Last Reviewed: 2026-03-07
- Last Verified: 2026-03-07
- Platforms: macOS
- Confidence: High
