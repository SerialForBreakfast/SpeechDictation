# U-009: Rotor-Friendly Structure

## Title

Use heading and section structure that enables efficient rotor navigation in dense content.

## Problem Statement

Without rotor-friendly landmarks, container structure, and predictable contextual action exposure, VoiceOver users must traverse dense screens linearly and lose efficient navigation paths.

## Rule

Screens with repeated sections, dense content, or contextual row actions should expose heading and structural semantics so users can jump efficiently, without making rotor fluency a prerequisite for core task completion.

## Rationale

Rotor navigation is a core VoiceOver efficiency mechanism; structure and action exposure directly affect discoverability and navigation cost for users who rely on headings and action menus to move quickly.

## How To Implement

### UIKit

- Mark true section landmarks with heading traits.
- Structure table/collection/form regions and containers so major sections are semantically distinct.
- Keep primary actions directly discoverable in the linear traversal path.
- Expose contextual or overflow row operations with accessibility custom actions when inline controls would overload the layout.
- Treat rotor support as acceleration, not the sole path to complete the task.
- Avoid over-marking every row as a heading.

### SwiftUI Interop Notes

- Confirm heading semantics remain intact when UIKit containers host SwiftUI sections.
- Re-test rotor behavior after screen composition changes, especially when container ownership or row-action placement changes.

## How To Test

### Accessibility Inspector

- Verify heading traits are present on intended landmarks.
- Verify hierarchy supports section-level navigation and meaningful containers.
- Verify contextual actions are attached to the intended row or element when applicable.

### VoiceOver Walkthrough

- Swipe linearly through the screen and confirm core tasks remain fully discoverable without rotor changes.
- Use rotor to navigate by headings.
- Confirm jumps land on expected semantic anchors.
- Open the actions menu on complex rows and confirm contextual actions are present without replacing primary controls.

### Optional XCUITest Hook

- Use structural proxies (presence of heading-labeled elements and contextual-action-bearing rows) for limited automation.

## Do / Don't

- Do: define headings for major sections in long forms.
- Do: expose contextual row operations through custom accessibility actions when direct controls would overload the row.
- Don't: mark decorative captions or every row title as headings.
- Don't: make primary task completion depend on rotor-only discovery.

## Citations

- [APPLE-AX-HUB] https://developer.apple.com/documentation/accessibility
- [APPLE-AX-TESTING] https://developer.apple.com/documentation/accessibility/performing-accessibility-testing-for-your-app
- [APPLE-WWDC23-AUDITS] https://developer.apple.com/videos/play/wwdc2023/10035/

## Quote Snippets (Optional)

- None included in this draft.

## Metadata

- Status: Accepted
- Last Reviewed: 2026-03-12
- Last Verified: 2026-03-12
- Platforms: iOS, iPadOS
- Confidence: Medium
