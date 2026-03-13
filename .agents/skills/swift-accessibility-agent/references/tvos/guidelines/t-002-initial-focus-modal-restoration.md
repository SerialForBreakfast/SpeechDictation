# T-002: Initial Focus and Focus Restoration for Modal Flows

## Title

Set deterministic initial focus and restore focus to a logical anchor when modals close on tvOS.

## Problem Statement

When modals open without clear initial focus, or dismiss without restoring focus context, users lose orientation and may be unable to resume their previous task.

## Rule

Each modal presentation on tvOS must define an explicit initial focus target and restore focus to a meaningful originating control (or nearest equivalent anchor) on dismissal.

## Rationale

tvOS relies on focus continuity for navigation. Modal transitions that break continuity introduce functional navigation defects.

## How To Implement

### UIKit (tvOS)

- Set the modal's initial focus via `preferredFocusEnvironments`.
- Keep a stable reference to the launch control or fallback anchor before presenting the modal.
- On dismiss, update focus so navigation resumes from that anchor, not an arbitrary top-level element.
- Re-evaluate focus restoration when modal content is async-loaded or state-driven.

### SwiftUI/UIKit Interop Notes

- In SwiftUI-hosted tvOS screens, verify focus anchors survive UIKit presentation/dismissal boundaries.
- Ensure representable wrappers do not reset focus to container roots after dismissal.

## Interop Ownership

- Host modal controller owns initial focus and restore-focus anchor lifecycle.
- Embedded content subtree owns element-level semantics and state announcements.
- Dismissal path owner must guarantee focus restoration for success and cancel paths.

## How To Test

### Accessibility Inspector

- Verify modal controls are focusable and correctly labeled.
- Verify background content is not incorrectly focusable while modal is active.

### VoiceOver Walkthrough

- Open modal from multiple entry points and confirm initial focus lands on the intended primary control.
- Dismiss modal and confirm focus returns to the launch control (or declared fallback anchor).
- Repeat with interrupted flows (e.g., async loading) and confirm no focus loss.

### Optional XCUITest Hook

- Add modal-open/modal-close tests asserting expected focused anchor controls before and after dismissal.

## Do / Don't

- Do: define an explicit focus anchor contract for each modal entry and exit path.
- Don't: allow default or incidental focus behavior to choose restoration targets.

## Citations

- [APPLE-TVOS-FOCUS] https://developer.apple.com/documentation/uikit/about-focus-interactions-for-apple-tv
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
