# T-007: Media Playback Controls and Spoken State Updates

## Title

Expose complete, focusable media controls with clear spoken playback state in tvOS media experiences.

## Problem Statement

If transport controls are hard to discover, poorly named, or missing state announcements, users cannot reliably control playback or understand current media status.

## Rule

tvOS media players must provide fully focusable transport controls, accurate labels/traits/values, and explicit spoken state updates for key playback changes.

## Rationale

Media is a primary tvOS use case. Accessibility failures in playback controls block core app functionality.

## How To Implement

### UIKit (tvOS)

- Use native playback controls where possible to inherit expected semantics.
- Ensure play/pause, scrub, captions, and audio options are reachable by directional focus.
- Provide stateful values (playing/paused, elapsed/remaining time, selected caption track).
- Keep control naming stable and disambiguated when multiple media actions are present.

### SwiftUI/UIKit Interop Notes

- Validate semantic forwarding for custom player overlays hosted across SwiftUI/UIKit boundaries.
- Ensure overlay presentation/dismissal does not hide required controls from focus.

## Interop Ownership

- Host playback surface owns focus entry and overlay lifecycle behavior.
- Embedded player controls own transport/action semantics and state values.
- Host and embedded layers must agree on one source of truth for playback state announcements.

## How To Test

### Accessibility Inspector

- Verify transport controls expose correct roles and labels.
- Verify time/progress and selected media-option values are available when stateful.

### VoiceOver Walkthrough

- Start, pause, seek, and change media options while confirming spoken updates reflect current state.
- Confirm captions/audio controls are reachable and announce selected option context.
- Confirm controls remain discoverable over dynamic video backgrounds.

### Optional XCUITest Hook

- Add playback state tests asserting label/value changes after play/pause/seek actions.

## Do / Don't

- Do: ensure each playback transition has an accessible state signal users can hear or inspect.
- Don't: hide critical transport actions behind non-obvious gestures or unlabeled overlay buttons.

## Citations

- [APPLE-UIKIT-ACCESSIBILITY] https://developer.apple.com/documentation/uikit/accessibility-for-uikit
- [APPLE-AX-HUB] https://developer.apple.com/documentation/accessibility
- [APPLE-HIG-ACCESSIBILITY] https://developer.apple.com/design/human-interface-guidelines/accessibility

## Quote Snippets (Optional)

- None included in this draft.

## Metadata

- Status: Draft
- Last Reviewed: 2026-03-07
- Last Verified: 2026-03-07
- Platforms: tvOS
- Confidence: Medium
