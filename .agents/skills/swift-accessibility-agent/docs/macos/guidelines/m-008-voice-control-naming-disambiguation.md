# M-008: Voice Control Naming and Command Disambiguation

## Title

Use distinct, speakable control names so macOS Voice Control can target actions without ambiguity.

## Problem Statement

When controls share vague or duplicate names, Voice Control users must over-specify commands or cannot reliably activate intended actions.

## Rule

Interactive controls in the same context must have distinct, speakable names and stable wording across states unless a state change requires a meaningfully different command target.

## Rationale

Voice Control depends on predictable naming. Ambiguous labels create command collisions and reduce task completion reliability.

## How To Implement

### SwiftUI (macOS)

- Use explicit accessibility labels for icon-only or repeated controls.
- Avoid generic labels like "More" or "Options" when multiple instances are present.
- Keep naming stable across state changes where function remains the same.
- Include contextual nouns for repeated actions in lists/tables.

### UIKit/AppKit Interop Notes

- For AppKit controls, ensure accessible names match intended voice command language.
- Verify SwiftUI-AppKit boundaries do not duplicate or truncate names.
- Ensure dynamic content updates preserve name uniqueness in the active context.

## How To Test

### Accessibility Inspector

- Inspect changed screens for duplicate interactive names in the same context.
- Verify icon-only controls expose meaningful labels.

### VoiceOver Walkthrough

- Confirm spoken labels are clear and distinct for neighboring/repeated controls.
- Validate that state changes do not remove needed disambiguation context.

### Optional XCUITest Hook

- Add checks for expected labels on high-risk repeated controls (toolbars, lists, row actions).

## Do / Don't

- Do: include contextual naming (for example, "Delete Draft", "Delete Attachment") when multiple similar actions exist.
- Don't: reuse the same short label for multiple controls in the same interaction scope.

## Citations

- [APPLE-AX-HUB] https://developer.apple.com/documentation/accessibility
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
