# Accessibility Architecture Principles (Pattern-Agnostic)

Last updated: 2026-03-07
Scope: SwiftUI/UIKit/AppKit codebases across iOS, iPadOS, tvOS, and macOS.

## Principle 1: Accessibility Is Component API

Rule: treat accessibility semantics (label/value/hint/traits/actions/grouping/order) as part of each reusable component contract.

Implementation target:
- Design system components
- Shared SwiftUI primitives
- UIKit/AppKit reusable views

## Principle 2: Semantics at Lowest Reusable Level

Rule: place accessibility behavior inside reusable components, not at per-screen call sites.

Expected outcome:
- Fewer regressions in repeated UI patterns
- Consistent semantics across product surfaces

## Principle 3: Interop Boundaries Need an Owner

Rule: at each SwiftUI/UIKit/AppKit boundary, assign ownership explicitly.

Ownership split:
- Host layer owns screen-level focus transitions and modal lifecycle focus.
- Embedded subtree owns element-level semantics and grouping.

## Principle 4: Guidelines Must Be Testable

Rule: no guideline is complete without verification steps.

Minimum verification:
- Accessibility Inspector pass
- VoiceOver walkthrough
- Dynamic Type/Larger Text sanity pass where applicable
- tvOS focus-navigation pass for tvOS surfaces

## Definition of Done (Architecture Level)

A component or screen change is accessibility-ready only when:
- Semantic contract is documented.
- Interop ownership is documented when frameworks are mixed.
- Verification evidence is attached to the change.
