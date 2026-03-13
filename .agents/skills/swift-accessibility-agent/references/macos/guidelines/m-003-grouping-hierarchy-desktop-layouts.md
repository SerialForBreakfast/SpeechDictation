# M-003: Grouping and Hierarchy for Complex Desktop Layouts

## Title

Expose clear grouping and hierarchy in complex macOS layouts so navigation preserves context.

## Problem Statement

When desktop layouts are exposed as flat or unlabeled containers, users lose structural context and must infer relationships between controls and content.

## Rule

Complex macOS screens must expose semantic group hierarchy that reflects visual and task structure, without obscuring individual interactive elements.

## Rationale

Desktop interfaces frequently include sidebars, toolbars, panes, and nested regions. Group semantics reduce cognitive overhead and improve traversal efficiency.

## How To Implement

### SwiftUI (macOS)

- Use structural containers that map cleanly to content regions.
- Label groups/regions when they provide meaningful navigation context.
- Keep child controls independently accessible.
- Avoid generic wrapper stacks that flatten semantic hierarchy.

### UIKit/AppKit Interop Notes

- For AppKit container views, ensure group/region semantics represent pane boundaries.
- Verify SwiftUI-AppKit hosting does not collapse nested hierarchy into generic groups.

## How To Test

### Accessibility Inspector

- Verify grouped regions align to task-relevant layout zones.
- Verify nested controls remain reachable and correctly labeled.

### VoiceOver Walkthrough

- Traverse across panes/regions and confirm transitions are understandable.
- Confirm repeated controls in different regions remain distinguishable.

### Optional XCUITest Hook

- Add presence checks for representative controls in each primary region.

## Do / Don't

- Do: model semantic regions to match how users understand the page.
- Don't: expose entire multi-pane layouts as one unlabeled accessibility group.

## Citations

- [APPLE-MACOS-NSACCESSIBILITY] https://developer.apple.com/documentation/appkit/nsaccessibility-swift.struct
- [APPLE-HIG-ACCESSIBILITY] https://developer.apple.com/design/human-interface-guidelines/accessibility
- [APPLE-AX-HUB] https://developer.apple.com/documentation/accessibility

## Quote Snippets (Optional)

- None included in this draft.

## Metadata

- Status: Draft
- Last Reviewed: 2026-03-07
- Last Verified: 2026-03-07
- Platforms: macOS
- Confidence: Medium
