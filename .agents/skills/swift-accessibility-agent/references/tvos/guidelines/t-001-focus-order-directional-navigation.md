# T-001: Focus Order and Directional Navigation Contracts

## Title

Ensure tvOS focus order and directional movement remain predictable across all interactive screens.

## Problem Statement

If directional focus movement is inconsistent, users can get trapped, skip key actions, or lose orientation in 10-foot interfaces.

## Rule

Every focusable screen must define predictable directional navigation and a logical initial focus target; no focus path may dead-end before the user can reach all primary actions.

## Rationale

tvOS interaction is focus-first. Users depend on directional movement reliability rather than touch exploration.

## How To Implement

### UIKit (tvOS)

- Build with native focusable controls before custom focusable views.
- Use `preferredFocusEnvironments` to guide initial focus for each screen and modal.
- Override focus update behavior only when default directional movement produces incorrect outcomes.
- Group related controls and avoid hidden/off-screen focusable artifacts.

### SwiftUI/UIKit Interop Notes

- In SwiftUI-on-tvos flows, verify hosted UIKit containers do not override or reset expected focus anchors.
- For representables, ensure child UIKit views participate correctly in tvOS focus evaluation.

## Interop Ownership

- Host container owns screen-entry and screen-exit focus targets.
- Embedded subtree owns element labels/values/traits/actions.
- Modal presenter owns restoration to prior focus anchor after dismiss.

## How To Test

### Accessibility Inspector

- Confirm focusable elements are exposed with correct labels/traits.
- Confirm hidden/decorative views are not focusable.

### VoiceOver Walkthrough

- Navigate each screen with remote directional movement and confirm deterministic focus transitions.
- Open/dismiss modal overlays and confirm focus enters modal content and restores to a logical anchor.
- Confirm all primary actions are reachable without trapped loops.

### Optional XCUITest Hook

- Add focus-smoke tests that assert primary controls become focused in expected sequence.

## Do / Don't

- Do: establish one clear initial focus anchor per screen and validate directional paths end to end.
- Don't: rely on incidental layout behavior that leaves controls unreachable from one or more directions.

## Citations

- [APPLE-UIKIT-ACCESSIBILITY] https://developer.apple.com/documentation/uikit/accessibility-for-uikit
- [APPLE-TVOS-FOCUS] https://developer.apple.com/documentation/uikit/about-focus-interactions-for-apple-tv
- [APPLE-AX-HUB] https://developer.apple.com/documentation/accessibility

## Quote Snippets (Optional)

- None included in this draft.

## Metadata

- Status: Draft
- Last Reviewed: 2026-03-07
- Last Verified: 2026-03-07
- Platforms: tvOS
- Confidence: Medium
