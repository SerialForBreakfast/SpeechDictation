# M-006: Table, Outline, and List Semantics for Desktop Data Views

## Title

Expose accurate semantics and navigation context for macOS table, outline, and list-heavy views.

## Problem Statement

If row/cell semantics or hierarchy are unclear, users cannot interpret large data sets, selection state, or expandable structure.

## Rule

macOS data views must expose row/item semantics, selection/expansion state, and contextual labels so users can navigate and operate large collections predictably.

## Rationale

Desktop applications often rely on dense data views. Accessibility semantics in these controls directly affect productivity and comprehension.

## How To Implement

### SwiftUI (macOS)

- Use native list/table controls where possible.
- Provide clear labels for columns/row actions and expose selected state.
- For expandable structures, expose hierarchy and expansion status clearly.

### UIKit/AppKit Interop Notes

- In AppKit table/outline implementations, ensure row/item role semantics and state are explicit.
- Verify custom cell content preserves accessible labels/actions.
- Ensure hosted SwiftUI row content does not remove structural context from AppKit containers.

## Interop Ownership

- Host table/outline container owns row hierarchy, selection model, and focus transitions.
- Embedded row/cell views own per-item labels, values, and action semantics.
- Boundary owner must verify structure remains exposed after row virtualization/reuse updates.

## How To Test

### Accessibility Inspector

- Verify row/item semantics, selected state, and expand/collapse state.
- Verify row actions remain discoverable and properly named.

### VoiceOver Walkthrough

- Navigate across rows and hierarchical nodes; confirm announcements include context and state.
- Perform selection/expansion actions and confirm updates are announced.

### Optional XCUITest Hook

- Add tests for row selection and expansion state transitions on critical views.

## Do / Don't

- Do: expose row context and hierarchy state as part of each data-view interaction.
- Don't: ship custom rows that hide actions or state behind non-semantic visuals.

## Citations

- [APPLE-MACOS-NSACCESSIBILITY] https://developer.apple.com/documentation/appkit/nsaccessibility-swift.struct
- [APPLE-HIG-ACCESSIBILITY] https://developer.apple.com/design/human-interface-guidelines/accessibility
- [APPLE-AX-TESTING] https://developer.apple.com/documentation/accessibility/performing-accessibility-testing-for-your-app

## Quote Snippets (Optional)

- None included in this draft.

## Metadata

- Status: Draft
- Last Reviewed: 2026-03-07
- Last Verified: 2026-03-07
- Platforms: macOS
- Confidence: Medium
