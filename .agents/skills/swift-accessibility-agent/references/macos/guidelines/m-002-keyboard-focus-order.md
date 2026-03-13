# M-002: Keyboard-First Focus Order and Full Keyboard Access

## Title

Ensure keyboard traversal order is logical and complete across all macOS workflows.

## Problem Statement

If keyboard focus order does not match interface structure, or key controls are unreachable, users relying on keyboard navigation cannot complete tasks reliably.

## Rule

Every macOS workflow must support full keyboard traversal with predictable order, visible focus feedback, and reachable primary/secondary actions without requiring pointer input.

## Rationale

macOS accessibility depends heavily on keyboard operability. Incomplete or disordered key navigation is a core usability and accessibility failure.

## How To Implement

### SwiftUI (macOS)

- Prefer native controls with built-in keyboard behavior.
- Structure view hierarchy so focus order follows visual and task order.
- Avoid custom key handling that bypasses standard traversal unless required, and document exceptions.
- Verify keyboard behavior for dialogs, sheets, and multi-pane layouts.

### UIKit/AppKit Interop Notes

- For AppKit views, ensure focus chain/order is coherent across custom containers.
- Validate that SwiftUI/AppKit boundaries preserve keyboard reachability and focus context.
- Ensure state transitions do not drop focus onto non-interactive containers.

## Interop Ownership

- Host container owns traversal entry order and cross-pane focus transitions.
- Embedded subtree owns control semantics and keyboard-operable action exposure.
- Boundary owner must ensure focus is not dropped onto non-interactive wrappers.

## How To Test

### Accessibility Inspector

- Verify focusable elements expose correct roles and labels.
- Verify no required controls are skipped in keyboard traversal paths.

### VoiceOver Walkthrough

- Run a full keyboard-only traversal of critical flows and confirm spoken context matches focus target.
- Confirm modal and window transitions preserve or restore focus to a logical anchor.

### Optional XCUITest Hook

- Add flow-level tests that validate reachability and state changes for keyboard-driven actions.

## Do / Don't

- Do: design and verify tab order as part of screen acceptance criteria.
- Don't: rely on pointer-only affordances for required task completion.

## Citations

- [APPLE-MACOS-NSACCESSIBILITY] https://developer.apple.com/documentation/appkit/nsaccessibility-swift.struct
- [APPLE-HIG-ACCESSIBILITY] https://developer.apple.com/design/human-interface-guidelines/accessibility
- [APPLE-WWDC25-MAC-ACCESSIBILITY] https://developer.apple.com/videos/play/wwdc2025/229/

## Quote Snippets (Optional)

- None included in this draft.

## Metadata

- Status: Draft
- Last Reviewed: 2026-03-07
- Last Verified: 2026-03-07
- Platforms: macOS
- Confidence: Medium
