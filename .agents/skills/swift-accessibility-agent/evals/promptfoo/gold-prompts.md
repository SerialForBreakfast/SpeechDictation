# Gold Prompt Catalog

Current baseline: `0.2.2`

## Purpose

These prompts are written to resemble real Swift developer questions on Apple platforms.
They intentionally avoid overfitting to the repository's internal naming.

## Authoring Principles

- Use natural developer phrasing.
- Allow common Apple API terms where developers would naturally use them.
- Do not pre-load the prompt with our internal rule wording.
- Prefer problem statements, implementation questions, and bug symptoms.
- Cover both framework-specific and cross-cutting guidance.

## Coverage Matrix

| ID | Coverage | User-like prompt | Expected routing |
|---|---|---|---|
| GP-001 | Identity | Who are you and what can you help me with in an Apple UI project? | identity only |
| GP-002 | UIKit grouping | I have a settings screen with a title, subtitle, and a switch in the same row. Should VoiceOver land on one thing or multiple things? | `uikit:u-005-grouping-containment.md`, `core:decision-matrix.md` |
| GP-003 | SwiftUI rotor structure | My SwiftUI dashboard has a lot of cards and section titles. How do I make it faster for VoiceOver users without forcing them to use special tricks? | `swiftui:g-009-rotors-when-and-why.md` |
| GP-004 | SwiftUI media | My player has live or on-demand state, captions, and buffering. What should be spoken, and what should stay out of the spoken output? | `swiftui:g-015-media-captions-audio-descriptions.md`, `testing:inspector-audit-checklist.md` |
| GP-005 | tvOS focus | On tvOS, focus sometimes jumps to the wrong button after a modal closes. What should I check first? | `tvos:t-001-focus-order-directional-navigation.md`, `tvos:t-002-initial-focus-modal-restoration.md` |
| GP-006 | macOS keyboard | In a macOS window, some controls are skipped when tabbing. Is this an accessibility bug or just keyboard setup? | `macos:m-002-keyboard-focus-order.md` |
| GP-007 | macOS interop | I embedded SwiftUI inside an AppKit container with NSHostingView and now VoiceOver reads less than before. What usually went wrong? | `macos:m-005-swiftui-appkit-interop-forwarding.md` |
| GP-008 | Regression workflow | This started breaking only on a newer OS build and feels framework-related. What repo guidance should I follow before I call it an Apple bug? | `core:known-os-issues-workflow.md`, `testing:regression-triage-playbook.md` |
| GP-009 | UIKit custom actions | I have a table row with swipe actions and extra commands. When should I keep real buttons visible versus using accessibility actions? | `uikit:u-007-accessibility-custom-actions.md`, `core:decision-matrix.md` |
| GP-010 | SwiftUI forms | My form has toggles, sliders, and nested rows. What are the common semantic mistakes to watch for? | `swiftui:g-014-lists-forms-complex-rows.md` |
| GP-011 | UIKit UILabel trigger | Tell me about UILabel accessibility. | `uikit:u-001-labels-meaningful-names.md`, `uikit:u-004-traits-roles.md` |
| GP-012 | macOS NSWindow trigger | Why does VoiceOver lose its place after I close a sheet in an NSWindow? | `macos:m-007-modal-window-focus-containment.md` |
| GP-013 | UITableView cell trigger | How should I handle accessibility in a UITableView cell that has text, a detail label, and a switch? | `uikit:u-014-table-collection-form-semantics.md`, `uikit:u-005-grouping-containment.md` |
| GP-014 | Negative: UILabel generic API | How do I animate a UILabel fading in? | no routing |
| GP-015 | Negative: UIButton styling | How do I change the title color of a UIButton for the disabled state? | no routing |
| GP-016 | Negative: SwiftUI layout | How do I center a view in SwiftUI? | no routing |
| GP-017 | Negative: NSWindow generic API | What does NSWindow do? | no routing |

## Notes

- `GP-001` is the first-turn identity probe.
- `GP-002` through `GP-013` should produce a `ROUTING:` line plus trust footer.
- `GP-014` through `GP-017` should not produce `ROUTING:` or the trust footer.
- Multi-domain prompts are intentional where real developer questions naturally span more than one doc.
