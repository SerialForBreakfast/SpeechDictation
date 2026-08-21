# G-009: Rotors - When and Why

## Title

Use rotor-relevant structure to accelerate navigation in dense content.

## Problem Statement

Without rotor-friendly landmarks, section structure, and predictable contextual action exposure, VoiceOver users must traverse dense screens linearly and may miss efficient paths through repeated content.

## Rule

Screens with repeated sections, dense content, or contextual row actions should expose rotor-friendly landmarks and action surfaces so users can jump efficiently, without making rotor fluency a prerequisite for core task completion.

## Rationale

Rotor navigation is a core VoiceOver efficiency mechanism. Proper structure and action exposure improve discoverability and reduce interaction cost, especially for users who actively use headings and action menus to navigate at speed.

## How To Implement

### SwiftUI

- Mark section headers with heading semantics where they represent navigation landmarks.
- Structure lists/forms so major regions and containers are semantically distinct.
- Use grouping intentionally so rotor jumps land on meaningful units rather than noisy fragments.
- Pair contextual row operations with explicit accessibility actions; keep primary actions directly discoverable in linear navigation.
- Treat rotor support as acceleration, not the sole path to complete the task.
- Avoid over-labeling every item as a heading; reserve for true landmarks.
- Re-test rotor behavior after major layout or data-model changes.

### UIKit Interop Notes

- Ensure UIKit-hosted sections preserve heading/landmark semantics when embedded with SwiftUI content.
- Validate mixed stacks where container composition may flatten structure or detach row-level actions from their intended container.

## How To Test

### Accessibility Inspector

- Verify heading traits are present on intended landmarks.
- Verify hierarchy structure supports navigation by sections and meaningful containers.
- Verify contextual actions are attached to the intended row or element when applicable.

### VoiceOver Walkthrough

- Swipe linearly through the screen and confirm core tasks remain fully discoverable without rotor changes.
- Use rotor navigation to move by headings/landmarks.
- Confirm jumps land on expected semantic anchors and preserve context.
- Open the actions menu on complex rows and confirm contextual actions are present without replacing primary controls.

### Optional XCUITest Hook

- Limited direct rotor automation; use structural assertions (presence of heading-labeled elements and contextual-action-bearing rows) as proxies.

## Do / Don't

- Do: define headings for major sections in long forms and content-heavy screens.
- Do: expose contextual row operations through accessibility actions when direct controls would overload the row.
- Don't: mark decorative captions or every row title as a heading.
- Don't: make primary task completion depend on rotor-only discovery.

## Citations

- [APPLE-VIEW-ACCESSIBILITY] https://developer.apple.com/documentation/swiftui/view-accessibility
- [APPLE-WWDC24-SWIFTUI] https://developer.apple.com/videos/play/wwdc2024/10073/
- [APPLE-AX-TESTING] https://developer.apple.com/documentation/accessibility/performing-accessibility-testing-for-your-app

## Quote Snippets (Optional)

- None included in this draft.

## Metadata

- Status: Accepted
- Last Reviewed: 2026-03-12
- Last Verified: 2026-03-12
- Platforms: iOS, iPadOS
- Confidence: Medium
