# T-005: Custom Actions for Remote-First Interaction Models

## Title

Provide accessible custom actions when remote-first interaction cannot expose all required tasks directly.

## Problem Statement

If non-obvious gestures or hidden UI affordances are required for key tasks, users may not discover or complete those actions.

## Rule

When primary tvOS controls cannot directly expose all needed operations, provide discoverable accessibility custom actions with stable names and predictable results.

## Rationale

Remote-first interfaces can constrain direct manipulation. Custom actions preserve functionality for assistive-tech users when designed clearly.

## How To Implement

### UIKit (tvOS)

- Prefer direct controls first; add custom actions only for overflow or contextual operations.
- Use concise, verb-first action names aligned to user intent.
- Keep action ordering stable for repeated items.
- Ensure action completion updates visible and spoken state.

### SwiftUI/UIKit Interop Notes

- Validate custom actions on hosted views across SwiftUI/UIKit boundaries.
- Ensure representables forward actions and state updates correctly.

## How To Test

### Accessibility Inspector

- Verify custom actions are attached only where needed and are correctly named.
- Verify no duplicate or conflicting action names within the same context.

### VoiceOver Walkthrough

- Invoke each custom action and confirm behavior matches its name.
- Confirm state/result announcements occur after action completion.

### Optional XCUITest Hook

- Add targeted tests for high-value custom action surfaces and resulting state changes.

## Do / Don't

- Do: use custom actions to close specific interaction gaps in remote workflows.
- Don't: replace straightforward visible controls with hidden action menus.

## Citations

- [APPLE-UIKIT-ACCESSIBILITY] https://developer.apple.com/documentation/uikit/accessibility-for-uikit
- [APPLE-AX-HUB] https://developer.apple.com/documentation/accessibility
- [APPLE-WWDC23-SWIFTUI-UIKIT] https://developer.apple.com/videos/play/wwdc2023/10036/

## Quote Snippets (Optional)

- None included in this draft.

## Metadata

- Status: Draft
- Last Reviewed: 2026-03-07
- Last Verified: 2026-03-07
- Platforms: tvOS
- Confidence: Medium
