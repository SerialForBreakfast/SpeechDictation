# Accessibility Architecture Principles (Pattern-Agnostic)

Last updated: 2026-03-12
Scope: SwiftUI/UIKit/AppKit codebases across iOS, iPadOS, tvOS, and macOS.

## Principle 1: Accessibility Is Component API

Rule: treat accessibility semantics (label/value/hint/traits/actions/grouping/order/landmarks) as part of each reusable component contract.

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

## Principle 4: Acceleration Must Not Be Exclusive

Rule: rotor landmarks and custom actions should accelerate navigation and overflow tasks, but primary task completion must remain possible through direct, linear navigation.

Expected outcome:
- Users with low rotor familiarity can still complete core flows.
- Users with high rotor fluency gain faster navigation and contextual action access.
- Design decisions do not hide safety-critical or primary actions behind rotor-only affordances.

## Principle 5: Dense Surfaces Need a Navigation Strategy

Rule: data-dense screens, repeated sections, and complex rows must define section landmarks, grouping strategy, and action-exposure model at the container level.

Implementation target:
- Lists, feeds, dashboards, forms, collection layouts
- Compound rows/cards with secondary actions
- Mixed-framework host containers

## Principle 6: Rich Dynamic State Needs an Inspection Contract

Rule: when runtime state is richer than what should be spoken to users, expose a narrow inspection contract for debug/test workflows.

Required characteristics:
- Capture only task-relevant state that affects audit or regression diagnosis.
- Keep ownership explicit at the component or interop boundary.
- Do not require inspection-only metadata for user task completion.

Typical examples:
- Media stream kind, seekability, buffering state, playback rate, selected caption/audio options, PiP/external playback, ad state.

## Principle 7: Guidelines Must Be Testable

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
- Dense surfaces document landmark/grouping/action strategy when applicable.
- Supplemental inspection contract is documented when dynamic state materially exceeds spoken output.
- Verification evidence is attached to the change.
