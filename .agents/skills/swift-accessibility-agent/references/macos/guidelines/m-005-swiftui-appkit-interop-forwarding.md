# M-005: SwiftUI-in-AppKit Interop Semantic Forwarding

## Title

Preserve accessibility semantics when SwiftUI and AppKit views are composed in mixed macOS stacks.

## Problem Statement

Interop boundaries can flatten or drop roles, labels, and actions, causing controls to become hard to discover or operate.

## Rule

Any SwiftUI-AppKit integration point must be validated for semantic forwarding so accessibility roles, labels, values, actions, and focus behavior remain equivalent across hosting boundaries.

## Rationale

Mixed UI stacks are a frequent source of accessibility regressions because semantics may not propagate automatically through wrappers/containers.

## How To Implement

### SwiftUI (macOS)

- Prefer native SwiftUI controls with explicit accessibility modifiers only when needed.
- Validate semantics after embedding SwiftUI in AppKit containers.
- Keep identifier and naming conventions stable across hosted boundaries.

### UIKit/AppKit Interop Notes

- For `NSHostingView`/AppKit container layers, verify child semantics are not flattened.
- Forward required accessibility properties for wrapped custom AppKit views.
- Re-check focus and announcement behavior when container hierarchy changes.

## How To Test

### Accessibility Inspector

- Compare semantics before and after hosting boundary introduction.
- Verify roles, labels, values, and actions persist on child controls.

### VoiceOver Walkthrough

- Traverse interop screens and confirm control announcements and focus behavior match expectations.
- Validate modal and dynamic updates across hosted boundaries.

### Optional XCUITest Hook

- Add regression checks for representative interop surfaces (control presence + key state updates).

## Do / Don't

- Do: treat every hosting boundary as a required accessibility regression checkpoint.
- Don't: assume semantics automatically transfer from one framework layer to another.

## Citations

- [APPLE-WWDC23-SWIFTUI-UIKIT] https://developer.apple.com/videos/play/wwdc2023/10036/
- [APPLE-MACOS-NSACCESSIBILITY] https://developer.apple.com/documentation/appkit/nsaccessibility-swift.struct
- [APPLE-AX-TESTING] https://developer.apple.com/documentation/accessibility/performing-accessibility-testing-for-your-app

## Quote Snippets (Optional)

- None included in this draft.

## Metadata

- Status: Draft
- Last Reviewed: 2026-03-07
- Last Verified: 2026-03-07
- Platforms: macOS
- Confidence: Medium
