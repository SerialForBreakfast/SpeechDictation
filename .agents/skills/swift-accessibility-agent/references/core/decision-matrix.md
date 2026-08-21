# Accessibility Alternatives Decision Matrix

Last updated: 2026-03-12
Scope: SwiftUI/UIKit/AppKit across iOS, iPadOS, tvOS, macOS, visionOS.

## Purpose

Provide deterministic guidance for choosing between multiple valid accessibility implementation patterns.

## Decision Matrix

| Problem | Alternative A | Alternative B | Use A When | Use B When | Required Verification |
|---|---|---|---|---|---|
| Compound row/card semantics | `accessibilityElement(children: .combine)` | `accessibilityElement(children: .contain)` | Row has one primary action and children should read as one unit | Row has multiple independently actionable child controls | Inspector hierarchy + VoiceOver swipe order |
| Dense-screen navigation | Linear-only structure | Heading/region landmarks for rotor navigation | Screen is short and users do not need to jump between repeated sections | Screen has repeated sections, dashboards, long forms, or summary/detail regions | Inspector heading/region check + VoiceOver linear path + rotor traversal |
| Complex visual (chart/canvas/custom drawing) | `accessibilityChildren` synthetic elements | `accessibilityRepresentation` alternate view | Users need per-item navigation/state detail | One clear alternate semantic summary/control is sufficient | Inspector tree includes expected items + VoiceOver announces intended context |
| Action exposure | Visible direct controls | Custom accessibility actions | Primary actions are common and should be immediately discoverable | Overflow/context actions cannot fit directly in UI | VoiceOver action discovery + result-state announcement check |
| Compound-row actions | Inline child controls | Row-level custom accessibility actions | Action is primary, frequent, safety-critical, or benefits from direct discovery | Action is contextual/overflow and direct controls would overload the row | Linear discovery check + actions menu check + result-state announcement |
| Focus behavior after navigation/modal | Structural/default focus behavior | Explicit focus target + restore anchor logic | Default behavior is deterministic and testable | Default behavior causes focus loss/traps/jumps | VoiceOver focus-entry/focus-exit walkthrough + modal cycle checks |
| Mixed-framework semantics ownership | Host owns everything ad hoc | Explicit split: host owns screen focus lifecycle, subtree owns element semantics | Never preferred for long-term maintenance | Always for SwiftUI/UIKit/AppKit interop boundaries | Interop boundary contract + Inspector/VoiceOver regression pass |
| Control choice | Native system control | Custom control with explicit semantics | Native control satisfies product requirements | Visual/interaction requirements cannot be met with native controls | Role/label/value/actions parity vs native equivalent |
| Rich dynamic state exposure | Spoken accessibility surface only | Spoken surface + supplemental inspection contract | Spoken label/value/action fully describes task-relevant state | Underlying state affects diagnosis but would add noise if spoken directly (media stream type, buffering, selected tracks, PiP/external playback, ad state) | Inspector pass + supplemental inspection snapshot + VoiceOver task walkthrough |
| Regression detection | Manual checks only | Manual + XCUITest smoke checks | Very low-risk cosmetic-only changes | Any change touching interaction, semantics, focus, or dynamic state | Inspector + VoiceOver + XCUITest smoke pass |

## Platform Notes

- tvOS: bias toward deterministic focus lifecycle and explicit restore anchors on modal flows.
- macOS: bias toward keyboard-first operability and stable focus chain.
- visionOS: bias toward alternatives that avoid gesture-only dependency and preserve semantic equivalence.

## Selection Protocol

1. Identify symptom or UI pattern from backlog topic.
2. Choose matrix row and document selected alternative.
3. Record why rejected alternative is less suitable.
4. Execute required verification listed for that row.
5. If regression risk is known, link matching `AX-BUG-###` entry.
