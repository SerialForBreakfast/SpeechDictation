# M-009: Contrast, Reduced Transparency, and Non-Color Cues

## Title

Maintain readable contrast, support reduced-transparency environments, and avoid color-only meaning in macOS UIs.

## Problem Statement

Desktop interfaces with subtle contrast, transparency-heavy layers, or color-only status cues can become unreadable or ambiguous for users with low vision and related accessibility needs.

## Rule

macOS interfaces must preserve contrast across window/background states, remain legible when transparency effects are reduced, and communicate critical status with non-color cues.

## Rationale

macOS visual environments vary by wallpaper, vibrancy, and user accessibility settings. Robust semantics and visual redundancy prevent state loss across those conditions.

## How To Implement

### SwiftUI (macOS)

- Use semantic system colors and materials instead of hard-coded decorative palettes.
- Provide text/icon/shape reinforcement for selected, warning, and error states.
- Verify legibility in sidebars, toolbars, and overlays that use translucency.
- Favor explicit labels for status chips/tags that might otherwise be color-only.

### UIKit/AppKit Interop Notes

- In AppKit views, verify contrast under active/inactive window states.
- Ensure custom `NSView` drawing still conveys state when transparency effects are reduced.
- Confirm SwiftUI-AppKit boundaries preserve state cues and do not drop text/icon reinforcement.

## How To Test

### Accessibility Inspector

- Verify actionable text and controls meet contrast expectations.
- Verify state remains interpretable without color-only differentiation.

### VoiceOver Walkthrough

- Confirm spoken output conveys state independently of color styling.
- Verify status transitions announce meaningful updated context.

### Optional XCUITest Hook

- Add assertions that state transitions update textual/icon indicators, not only tint/color.

## Do / Don't

- Do: design every critical state with color plus another cue (text, icon, or shape).
- Don't: rely on vibrancy/transparency styling that makes controls unreadable in varied desktop contexts.

## Citations

- [APPLE-HIG-ACCESSIBILITY] https://developer.apple.com/design/human-interface-guidelines/accessibility
- [APPLE-MACOS-NSACCESSIBILITY] https://developer.apple.com/documentation/appkit/nsaccessibility-swift.struct
- [APPLE-WWDC25-MAC-ACCESSIBILITY] https://developer.apple.com/videos/play/wwdc2025/229/

## Quote Snippets (Optional)

- None included in this draft.

## Metadata

- Status: Draft
- Last Reviewed: 2026-03-07
- Last Verified: 2026-03-07
- Platforms: macOS
- Confidence: Medium
