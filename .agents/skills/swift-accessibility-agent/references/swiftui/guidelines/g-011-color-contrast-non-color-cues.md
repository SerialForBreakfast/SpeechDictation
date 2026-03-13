# G-011: Color, Contrast, and Non-Color Cues

## Title

Use sufficient contrast and never rely on color alone to communicate meaning.

## Problem Statement

Color-only communication and low contrast can make state, errors, and actions inaccessible for users with low vision or color-vision differences.

## Rule

Any meaningful status, feedback, or interaction cue conveyed with color must also be conveyed with text, symbol, shape, or another non-color indicator, and text/controls must maintain sufficient contrast.

## Rationale

Accessible interfaces require redundant cues and legible contrast so information remains perceivable under varied vision capabilities and system accessibility settings.

## How To Implement

### SwiftUI

- Pair color changes with semantic text or icon changes (for example, "Error" + symbol, not red-only text).
- Use system colors/materials where possible to inherit accessibility-aware behavior.
- Avoid encoding selection/validation state solely by tint differences.
- Check both light and dark appearances if supported.

### UIKit Interop Notes

- Ensure UIKit-backed controls use contrast-safe color tokens consistent with SwiftUI theme definitions.
- Validate mixed screens for color-state inconsistencies where UIKit and SwiftUI styling overlap.

## How To Test

### Accessibility Inspector

- Run contrast and visual checks for text and interactive elements.
- Verify status indicators include non-color semantic cues.

### VoiceOver Walkthrough

- Confirm spoken output includes state/error context that might otherwise be presented visually by color.

### Optional XCUITest Hook

- Assert presence of explicit state text/symbols for critical statuses (error, success, selection).

## Do / Don't

- Do: combine icon/text labels with color to indicate status.
- Don't: indicate required, selected, or error states with color alone.

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
