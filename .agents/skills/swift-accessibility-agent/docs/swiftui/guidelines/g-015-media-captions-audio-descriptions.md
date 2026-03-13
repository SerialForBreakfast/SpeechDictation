# G-015: Media - Captions, Audio Descriptions, and Accessible Controls

## Title

Provide accessible media alternatives and fully labeled playback controls.

## Problem Statement

Without captions, descriptions, and accessible controls, media content becomes partially or fully unusable for many users.

## Rule

Media experiences must provide accessible playback control semantics and support captions/subtitles for spoken content; when visual-only meaning is important, provide descriptive alternatives.

## Rationale

Media accessibility requires both content alternatives and operable controls. Users must be able to perceive meaning and control playback independently.

## How To Implement

### SwiftUI

- Ensure play/pause/seek/speed controls have clear labels, values, and roles.
- Expose current playback state and timing readouts accessibly.
- Provide caption/subtitle availability where spoken media exists.
- Avoid gesture-only media controls without accessible action alternatives.

### UIKit Interop Notes

- When wrapping AVKit/UIKit media controllers, verify control labels and states are exposed correctly.
- Ensure custom overlay controls do not block or duplicate native accessible media controls.

## How To Test

### Accessibility Inspector

- Verify all media controls are discoverable and labeled.
- Verify state/value updates (playing/paused, position) are exposed.
- Verify caption-related controls/options are reachable when available.

### VoiceOver Walkthrough

- Navigate media controls and confirm each control announces purpose and state.
- Enable captions/subtitles and verify the flow is operable without touch exploration.

### Optional XCUITest Hook

- Add smoke tests for playback-state transitions and caption-toggle control availability.

## Do / Don't

- Do: provide clear, labeled controls for play, pause, and timeline navigation.
- Don't: hide primary media controls behind unlabeled gestures or icon-only overlays.

## Citations

- [APPLE-HIG-ACCESSIBILITY] https://developer.apple.com/design/human-interface-guidelines/accessibility
- [APPLE-AX-HUB] https://developer.apple.com/documentation/accessibility
- [ASC-ANL-OVERVIEW] https://developer.apple.com/help/app-store-connect/manage-app-accessibility/overview-of-accessibility-nutrition-labels/

## Quote Snippets (Optional)

- None included in this draft.

## Metadata

- Status: Accepted
- Last Reviewed: 2026-03-07
- Last Verified: 2026-03-07
- Platforms: iOS, iPadOS
- Confidence: Medium
