# M-007: Modal and Window Focus Containment and Restoration

## Title

Contain assistive focus within active macOS modal/window context and restore focus to a logical anchor when that context closes.

## Problem Statement

If focus leaks outside active modal/window context, or does not restore predictably on close, users lose task context and may be unable to continue workflows.

## Rule

When a modal sheet, panel, or window takes focus on macOS, focus must remain within that context until dismissal, then restore to the originating control or nearest meaningful anchor.

## Rationale

macOS accessibility workflows rely on stable focus context across window and modal transitions. Broken containment or restoration causes major navigation regressions.

## How To Implement

### SwiftUI (macOS)

- Present modal content with a clear primary focus target.
- Keep a deterministic return anchor in the presenting context.
- On dismissal, explicitly return focus to that anchor when default behavior is insufficient.
- Re-test focus behavior when modal content is conditionally rendered or async-loaded.

### UIKit/AppKit Interop Notes

- In AppKit-based windows/sheets, ensure accessibility focus does not remain on background controls while modal content is active.
- For SwiftUI-AppKit hosting boundaries, confirm focus restoration is not lost at container transitions.
- Ensure state announcements after dismissal reflect the newly active context.

## Interop Ownership

- Modal/window host owns focus containment boundaries and restore anchor.
- Embedded content owns element semantics and contextual state announcements.
- Dismissal owner must verify both completion and cancel paths return focus correctly.

## How To Test

### Accessibility Inspector

- Verify only active modal/window controls are focusable during modal presentation.
- Verify presenting context controls re-enter focus order after dismissal.

### VoiceOver Walkthrough

- Open each modal/window flow and confirm focus lands on intended initial control.
- Dismiss context and confirm focus returns to launch anchor (or documented fallback).
- Repeat for cancellation and completion paths.

### Optional XCUITest Hook

- Add open/close modal tests asserting anchor reachability before and after transitions.

## Do / Don't

- Do: define explicit focus-entry and focus-exit anchors for each modal/window flow.
- Don't: rely on implicit focus behavior when multiple windows/sheets can appear in sequence.

## Citations

- [APPLE-MACOS-NSACCESSIBILITY] https://developer.apple.com/documentation/appkit/nsaccessibility-swift.struct
- [APPLE-WWDC25-MAC-ACCESSIBILITY] https://developer.apple.com/videos/play/wwdc2025/229/
- [APPLE-AX-TESTING] https://developer.apple.com/documentation/accessibility/performing-accessibility-testing-for-your-app

## Quote Snippets (Optional)

- None included in this draft.

## Metadata

- Status: Draft
- Last Reviewed: 2026-03-07
- Last Verified: 2026-03-07
- Platforms: macOS
- Confidence: Medium
