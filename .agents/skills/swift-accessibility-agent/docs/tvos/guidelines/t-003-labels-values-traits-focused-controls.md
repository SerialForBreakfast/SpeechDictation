# T-003: Labels, Values, and Traits for Focused Controls

## Title

Expose complete labels, values, and traits for all focusable controls in tvOS interfaces.

## Problem Statement

When focused controls have missing or ambiguous semantics, VoiceOver announcements are unclear and users cannot confidently decide what action to take.

## Rule

Every focusable tvOS control must provide a meaningful label, include value/state when applicable, and expose traits that match actual control behavior.

## Rationale

In tvOS, focus is the primary interaction model, and users rely on spoken context for each focused item. Incomplete semantics create interaction risk and navigation errors.

## How To Implement

### UIKit (tvOS)

- Prefer native focusable controls that provide semantic defaults.
- Set `accessibilityLabel` for icon-only or context-dependent controls.
- Set `accessibilityValue` for stateful controls (selection, playback state, toggled states).
- Apply traits that represent behavior accurately (button, selected, adjustable, etc.).

### SwiftUI/UIKit Interop Notes

- Verify semantic forwarding when SwiftUI views are hosted inside UIKit containers on tvOS.
- Ensure representable wrappers do not strip labels/values/traits from child controls.

## How To Test

### Accessibility Inspector

- Confirm each focusable element exposes label and role/traits.
- Confirm stateful controls expose current value.
- Confirm decorative/non-interactive elements are not focusable.

### VoiceOver Walkthrough

- Move focus through all key controls and confirm spoken output includes clear label + role + state context.
- Toggle stateful controls and confirm updated values are announced.
- Check repeated controls in a row/list for naming disambiguation.

### Optional XCUITest Hook

- Assert presence and state-output changes for key controls with stable identifiers.

## Do / Don't

- Do: include explicit semantics for every focusable item, especially icon-only controls.
- Don't: expose generic or duplicate names that force users to guess control purpose.

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
