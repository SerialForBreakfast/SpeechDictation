# U-012: Reduced Motion Handling

## Title

Respect Reduce Motion by removing non-essential animation while preserving clarity.

## Problem Statement

Motion-heavy transitions can cause discomfort and reduce usability when users request reduced motion.

## Rule

When Reduce Motion is enabled, replace non-essential animations with low-motion alternatives that preserve state-change clarity.

## Rationale

Accessibility settings reflect explicit user preferences and must be respected without removing critical feedback.

## How To Implement

### UIKit

- Detect reduced-motion settings and conditionally reduce animation intensity.
- Prefer fades or immediate state updates over large motion transitions.
- Ensure critical state changes remain clear without motion cues.

### SwiftUI Interop Notes

- Keep transition behavior consistent when UIKit and SwiftUI components are combined.
- Validate that hosted SwiftUI transitions do not reintroduce heavy motion.

## How To Test

### Accessibility Inspector

- Verify key transitions remain understandable with reduced motion.
- Verify state changes remain visible without motion dependence.

### VoiceOver Walkthrough

- Enable Reduce Motion and run core flows.
- Confirm navigation/state context remains clear after transitions.

### Optional XCUITest Hook

- Add smoke tests for final UI state after transitions when reduced-motion mode is on.

## Do / Don't

- Do: replace spring-heavy animations with subtle fades or direct updates.
- Don't: hide completion feedback in motion-only effects.

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
