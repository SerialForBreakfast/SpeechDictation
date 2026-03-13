# T-009: Color Contrast and Non-Color Cues in 10-Foot UI

## Title

Ensure tvOS interfaces maintain readable contrast and communicate state with more than color.

## Problem Statement

At living-room viewing distance, low contrast and color-only signaling make status and actions difficult to perceive, especially for users with low vision or color-vision differences.

## Rule

Text, controls, and critical status indicators in tvOS UIs must maintain sufficient contrast and must not rely on color alone to convey meaning.

## Rationale

tvOS is a 10-foot experience where readability constraints are amplified. Non-color reinforcement and clear contrast are required for reliable comprehension.

## How To Implement

### UIKit (tvOS)

- Use system semantic colors and native controls where possible.
- Pair color state with secondary cues (icon, text, shape, position, or explicit label).
- Ensure focus indicators remain visually distinct against all backgrounds.
- Re-check overlays, gradients, and media backdrops where contrast often regresses.

### SwiftUI/UIKit Interop Notes

- Verify hosted SwiftUI content and UIKit containers resolve semantic colors consistently.
- Ensure custom representables preserve both contrast and non-color state cues.

## How To Test

### Accessibility Inspector

- Run contrast checks for primary text and actionable controls.
- Verify state differences remain understandable when color distinctions are reduced.

### VoiceOver Walkthrough

- Confirm spoken labels/values communicate state without depending on visual color.
- Confirm focused controls announce clear state context for selected/on/off modes.

### Optional XCUITest Hook

- Add state-change checks asserting visible text/icon cues update with control state.

## Do / Don't

- Do: pair color with textual or symbolic state signals and validate contrast on actual tvOS backgrounds.
- Don't: indicate selection, errors, or availability with color-only badges/highlights.

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
