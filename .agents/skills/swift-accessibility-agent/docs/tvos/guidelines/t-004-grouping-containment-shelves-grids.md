# T-004: Grouping and Semantic Containment in Shelf/Grid UIs

## Title

Structure shelf and grid layouts so focus traversal and announcements reflect meaningful content groups.

## Problem Statement

When grouped content is exposed as flat, unstructured focus targets, users lose context about where items belong and navigation becomes inefficient.

## Rule

tvOS shelf/grid interfaces must expose clear semantic grouping so focus movement and announcements preserve section context without hiding actionable children.

## Rationale

Large media catalogs are a common tvOS pattern. Group-level context improves orientation and reduces navigation errors.

## How To Implement

### UIKit (tvOS)

- Use collection and container structures that preserve section boundaries.
- Label section/group containers when they provide navigation context.
- Ensure child items remain independently focusable and actionable.
- Avoid over-grouping that collapses important item-level semantics.

### SwiftUI/UIKit Interop Notes

- Verify grouping semantics survive SwiftUI/UIKit hosting boundaries.
- Ensure representables do not flatten section context into unlabeled containers.

## How To Test

### Accessibility Inspector

- Verify section/group containers expose meaningful labels when needed.
- Verify each child item remains focusable with complete semantics.

### VoiceOver Walkthrough

- Traverse across shelves/rows and confirm users can distinguish section transitions.
- Confirm item announcements include enough context to disambiguate repeated titles.

### Optional XCUITest Hook

- Add smoke tests for representative section/item identifiers across key catalog screens.

## Do / Don't

- Do: expose section context while preserving item-level interaction semantics.
- Don't: flatten large catalog UIs into unlabeled, repetitive item streams.

## Citations

- [APPLE-UIKIT-ACCESSIBILITY] https://developer.apple.com/documentation/uikit/accessibility-for-uikit
- [APPLE-HIG-ACCESSIBILITY] https://developer.apple.com/design/human-interface-guidelines/accessibility
- [APPLE-AX-HUB] https://developer.apple.com/documentation/accessibility

## Quote Snippets (Optional)

- None included in this draft.

## Metadata

- Status: Draft
- Last Reviewed: 2026-03-07
- Last Verified: 2026-03-07
- Platforms: tvOS
- Confidence: Medium
