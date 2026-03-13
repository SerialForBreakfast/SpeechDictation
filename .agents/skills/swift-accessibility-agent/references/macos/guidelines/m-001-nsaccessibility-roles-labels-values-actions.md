# M-001: NSAccessibility Roles, Labels, Values, and Actions Baseline

## Title

Expose complete `NSAccessibility` semantics for every interactive AppKit and macOS custom view element.

## Problem Statement

When macOS controls lack accurate role/label/value/action semantics, assistive technologies announce incomplete information and users cannot reliably operate the interface.

## Rule

All interactive macOS elements must expose correct `NSAccessibility` role and label, include state/value where applicable, and support the expected accessibility action contract for that control type.

## Rationale

On macOS, `NSAccessibility` is the semantic contract used by VoiceOver and other assistive technologies. Missing contract fields create functional defects, not cosmetic issues.

## How To Implement

### SwiftUI (macOS)

- Prefer native SwiftUI controls that map to correct desktop semantics by default.
- Add explicit accessibility labels/values only when defaults are missing or ambiguous.
- Verify custom SwiftUI controls expose equivalent semantics to native control behavior.

### UIKit/AppKit Interop Notes

- For custom `NSView` content, implement required `NSAccessibility` role/value/action behavior explicitly.
- In SwiftUI-AppKit hosting boundaries, verify semantics are forwarded and not flattened at container edges.
- Emit accessibility-relevant state updates so announcements reflect current UI state.

## How To Test

### Accessibility Inspector

- Verify each interactive element exposes expected role, label, and value.
- Verify action availability aligns with control behavior.
- Verify custom controls are not surfaced as generic groups/static elements when interaction is expected.

### VoiceOver Walkthrough

- Traverse each key workflow and confirm spoken output includes role + label + state context.
- Confirm actions trigger expected behavior and announce updated state.

### Optional XCUITest Hook

- Assert key controls exist with stable identifiers and reflect state changes in visible labels/values.

## Do / Don't

- Do: treat `NSAccessibility` semantics as part of each control's acceptance criteria.
- Don't: ship custom `NSView` interactions without explicit role/label/value/action coverage.

## Citations

- [APPLE-MACOS-NSACCESSIBILITY] https://developer.apple.com/documentation/appkit/nsaccessibility-swift.struct
- [APPLE-AX-HUB] https://developer.apple.com/documentation/accessibility
- [APPLE-WWDC25-MAC-ACCESSIBILITY] https://developer.apple.com/videos/play/wwdc2025/229/

## Quote Snippets (Optional)

- None included in this draft.

## Metadata

- Status: Draft
- Last Reviewed: 2026-03-07
- Last Verified: 2026-03-07
- Platforms: macOS
- Confidence: Medium
