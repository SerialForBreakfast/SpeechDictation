# G-009: Rotors - When and Why

## Title

Use rotor-relevant structure to accelerate navigation in dense content.

## Problem Statement

Without rotor-friendly landmarks (such as headings or structured groups), VoiceOver users must traverse long screens linearly, increasing effort and error risk.

## Rule

Screens with repeated sections or dense content should expose rotor-friendly semantics (for example, headings and meaningful structure) so users can jump efficiently.

## Rationale

Rotor navigation is a core VoiceOver efficiency mechanism. Proper structure improves discoverability and reduces interaction cost.

## How To Implement

### SwiftUI

- Mark section headers with heading semantics where they represent navigation landmarks.
- Structure lists/forms so major regions are semantically distinct.
- Avoid over-labeling every item as a heading; reserve for true landmarks.
- Re-test rotor behavior after major layout or data-model changes.

### UIKit Interop Notes

- Ensure UIKit-hosted sections preserve heading/landmark semantics when embedded with SwiftUI content.
- Validate mixed stacks where container composition may flatten structure.

## How To Test

### Accessibility Inspector

- Verify heading traits are present on intended landmarks.
- Verify hierarchy structure supports navigation by sections.

### VoiceOver Walkthrough

- Use rotor navigation to move by headings/landmarks.
- Confirm jumps land on expected semantic anchors and preserve context.

### Optional XCUITest Hook

- Limited direct rotor automation; use structural assertions (presence of heading-labeled elements) as proxies.

## Do / Don't

- Do: define headings for major sections in long forms and content-heavy screens.
- Don't: mark decorative captions or every row title as a heading.

## Citations

- [APPLE-VIEW-ACCESSIBILITY] https://developer.apple.com/documentation/swiftui/view-accessibility
- [APPLE-WWDC24-SWIFTUI] https://developer.apple.com/videos/play/wwdc2024/10073/
- [APPLE-AX-TESTING] https://developer.apple.com/documentation/accessibility/performing-accessibility-testing-for-your-app

## Quote Snippets (Optional)

- None included in this draft.

## Metadata

- Status: Accepted
- Last Reviewed: 2026-03-07
- Last Verified: 2026-03-07
- Platforms: iOS, iPadOS
- Confidence: Medium
