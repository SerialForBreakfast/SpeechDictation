# U-009: Rotor-Friendly Structure

## Title

Use heading and section structure that enables efficient rotor navigation in dense content.

## Problem Statement

Without rotor-friendly landmarks, VoiceOver users must traverse long screens linearly, increasing effort and error risk.

## Rule

Screens with repeated sections or dense content should expose heading and structural semantics so users can jump efficiently.

## Rationale

Rotor navigation is a core VoiceOver efficiency mechanism; structure directly affects discoverability and navigation cost.

## How To Implement

### UIKit

- Mark true section landmarks with heading traits.
- Structure table/collection/form regions so major sections are semantically distinct.
- Avoid over-marking every row as a heading.

### SwiftUI Interop Notes

- Confirm heading semantics remain intact when UIKit containers host SwiftUI sections.
- Re-test rotor behavior after screen composition changes.

## How To Test

### Accessibility Inspector

- Verify heading traits are present on intended landmarks.
- Verify hierarchy supports section-level navigation.

### VoiceOver Walkthrough

- Use rotor to navigate by headings.
- Confirm jumps land on expected semantic anchors.

### Optional XCUITest Hook

- Use structural proxies (presence of heading-labeled elements) for limited automation.

## Do / Don't

- Do: define headings for major sections in long forms.
- Don't: mark decorative captions or every row title as headings.

## Citations

- [APPLE-AX-HUB] https://developer.apple.com/documentation/accessibility
- [APPLE-AX-TESTING] https://developer.apple.com/documentation/accessibility/performing-accessibility-testing-for-your-app
- [APPLE-WWDC23-AUDITS] https://developer.apple.com/videos/play/wwdc2023/10035/

## Quote Snippets (Optional)

- None included in this draft.

## Metadata

- Status: Accepted
- Last Reviewed: 2026-03-07
- Last Verified: 2026-03-07
- Platforms: iOS, iPadOS
- Confidence: Medium
