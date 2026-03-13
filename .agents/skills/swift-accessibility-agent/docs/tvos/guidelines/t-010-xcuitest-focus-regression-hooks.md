# T-010: XCUITest Focus Assertions and Regression Hooks

## Title

Use focused XCUITest hooks to catch deterministic tvOS accessibility regressions in focus and semantics.

## Problem Statement

Without automated guardrails, regressions in focus reachability and control semantics can repeatedly escape into manual testing.

## Rule

Maintain a compact tvOS accessibility smoke suite in XCUITest that checks focus reachability, critical control presence, and key state transitions, while treating manual assistive-tech validation as mandatory.

## Rationale

Automation can reliably catch repeat regressions, but cannot fully validate VoiceOver interaction quality or all focus semantics.

## How To Implement

### UIKit (tvOS)

- Add stable identifiers for critical controls and anchors.
- Add tests covering focus entry points, modal restore anchors, and playback/search state transitions.
- Keep assertions scoped to deterministic behavior to avoid brittle failures.

### SwiftUI/UIKit Interop Notes

- Ensure identifiers survive hosted-view boundaries and representable wrappers.
- Add regression checks for interop screens where focus/order issues have occurred.

## How To Test

### Accessibility Inspector

- Use inspector checks to validate semantics not covered by XCUITest assertions.

### VoiceOver Walkthrough

- Validate spoken output and qualitative focus behavior on representative end-to-end flows.

### Optional XCUITest Hook

- Run tvOS accessibility smoke tests on every PR for critical screens.
- Include modal open/close anchor assertions and core control state transitions.

## Do / Don't

- Do: treat XCUITest as regression guardrails for deterministic failures.
- Don't: treat passing automation as complete accessibility sign-off.

## Citations

- [APPLE-AX-TESTING] https://developer.apple.com/documentation/accessibility/performing-accessibility-testing-for-your-app
- [APPLE-AX-INSPECTOR] https://developer.apple.com/documentation/accessibility/accessibility-inspector
- [CASHAPP-ACCESSIBILITYSNAPSHOT] https://github.com/cashapp/AccessibilitySnapshot

## Quote Snippets (Optional)

- None included in this draft.

## Metadata

- Status: Draft
- Last Reviewed: 2026-03-07
- Last Verified: 2026-03-07
- Platforms: tvOS
- Confidence: High
