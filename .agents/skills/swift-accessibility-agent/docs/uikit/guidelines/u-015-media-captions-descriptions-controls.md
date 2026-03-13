# U-015: Media Captions, Descriptions, and Control Semantics

## Title

Provide accessible media alternatives and fully labeled playback controls.

## Problem Statement

Without captions, descriptions, and accessible controls, media content becomes partially or fully unusable for many users.

## Rule

Media experiences must provide accessible playback control semantics and support captions/subtitles for spoken content; when visual-only meaning is important, provide descriptive alternatives.

## Rationale

Media accessibility requires both perceivable alternatives and operable controls.

## How To Implement

### UIKit

- Ensure play/pause/seek/speed controls expose clear labels, values, and roles.
- Expose current playback state and timing readouts accessibly.
- Provide caption/subtitle options where spoken media exists.
- Avoid gesture-only media controls without accessible action alternatives.

### SwiftUI Interop Notes

- In mixed AVKit/SwiftUI flows, ensure control labels and state are consistent across layers.
- Verify custom overlays do not block native accessible controls.

## How To Test

### Accessibility Inspector

- Verify all media controls are discoverable and labeled.
- Verify playback state/value updates are exposed.
- Verify caption-related controls are reachable when available.

### VoiceOver Walkthrough

- Navigate media controls and confirm each control announces purpose and state.
- Enable captions/subtitles and verify operation without touch exploration.

### Optional XCUITest Hook

- Add smoke tests for playback-state transitions and caption-toggle availability.

## Do / Don't

- Do: provide clear labeled controls for play, pause, and timeline navigation.
- Don't: hide primary controls behind unlabeled gestures or icon-only overlays.

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
