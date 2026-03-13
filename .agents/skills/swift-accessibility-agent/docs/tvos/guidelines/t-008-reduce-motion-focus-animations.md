# T-008: Reduce Motion Handling for Focus Animations

## Title

Respect reduced-motion preferences in tvOS focus animations without losing navigation clarity.

## Problem Statement

Large parallax and transition effects can cause discomfort and disorientation when reduced-motion preferences are enabled, especially in focus-driven interfaces.

## Rule

tvOS UIs must provide reduced-motion behavior for focus and transition animations while preserving clear focus location, selection state, and navigation context.

## Rationale

Focus animation is central to tvOS navigation. Motion reduction must not remove orientation cues or make focus state ambiguous.

## How To Implement

### UIKit (tvOS)

- Prefer system animation behaviors that automatically adapt to accessibility settings.
- Reduce custom parallax, scaling, and camera-motion intensity when reduced motion is enabled.
- Keep non-motion cues for focus state (contrast ring, scale-lite highlight, text/icon state).
- Ensure state transitions remain understandable if animation timing/effects are minimized.

### SwiftUI/UIKit Interop Notes

- Verify reduced-motion behavior is consistent across hosted SwiftUI and UIKit focus surfaces.
- Ensure representable wrappers do not reintroduce high-motion effects in mixed stacks.

## How To Test

### Accessibility Inspector

- Confirm focusable controls remain semantically correct after reduced-motion variants are applied.
- Confirm focus indicators remain visible and distinguishable without motion-heavy effects.

### VoiceOver Walkthrough

- Enable reduced motion and navigate across key screens.
- Confirm focus movement remains predictable and perceivable.
- Confirm no core state information is conveyed only through animation.

### Optional XCUITest Hook

- Add regression checks for focus/selection state indicators that remain present in reduced-motion mode.

## Do / Don't

- Do: replace motion-heavy focus effects with stable visual cues when reduced motion is enabled.
- Don't: depend on animated movement alone to communicate focus or state changes.

## Citations

- [APPLE-HIG-ACCESSIBILITY] https://developer.apple.com/design/human-interface-guidelines/accessibility
- [APPLE-UIKIT-ACCESSIBILITY] https://developer.apple.com/documentation/uikit/accessibility-for-uikit
- [APPLE-AX-TESTING] https://developer.apple.com/documentation/accessibility/performing-accessibility-testing-for-your-app

## Quote Snippets (Optional)

- None included in this draft.

## Metadata

- Status: Draft
- Last Reviewed: 2026-03-07
- Last Verified: 2026-03-07
- Platforms: tvOS
- Confidence: Medium
