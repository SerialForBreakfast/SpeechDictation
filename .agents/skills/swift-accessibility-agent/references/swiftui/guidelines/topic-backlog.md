# Accessibility Guideline Topic Backlog

Last updated: 2026-03-07

## Priority Legend

- P0: Core semantics required for most UI work.
- P1: Common advanced semantics and interaction behavior.
- P2: Specialized or media-centric behavior.

## Acceptance Status Legend

- Drafted: Content exists but has not passed structured documentation QA.
- Tier-Validated: Supported by Tier-1 documentation and passed structured documentation QA.
- Accepted: Tier-validated and approved for active guidance use.

## Backlog

| topic_id | topic | priority | status | acceptance_status | review_evidence | citation_tiers | guideline_file |
|---|---|---|---|---|---|---|---|
| G-001 | Labels and meaningful names (images/icons) | P0 | Accepted | Accepted | Tier-1 documentation + structured doc QA (2026-03-07) | Tier-1 | docs/swiftui/guidelines/g-001-labels-meaningful-names.md |
| G-002 | Hints: when to use vs omit | P0 | Accepted | Accepted | Tier-1 documentation + structured doc QA (2026-03-07) | Tier-1 | docs/swiftui/guidelines/g-002-hints-when-to-use.md |
| G-003 | Values for stateful controls/readouts | P0 | Accepted | Accepted | Tier-1 documentation + structured doc QA (2026-03-07) | Tier-1 | docs/swiftui/guidelines/g-003-values-stateful-controls.md |
| G-004 | Traits/roles: headers, buttons, selected, adjustable | P0 | Accepted | Accepted | Tier-1 documentation + structured doc QA (2026-03-07) | Tier-1 | docs/swiftui/guidelines/g-004-traits-roles.md |
| G-005 | Grouping and containment (combine/contain/ignore) | P0 | Accepted | Accepted | Tier-1 documentation + structured doc QA (2026-03-07) | Tier-1 | docs/swiftui/guidelines/g-005-grouping-containment.md |
| G-006 | Focus and reading order, sort priority | P0 | Accepted | Accepted | Tier-1 documentation + structured doc QA (2026-03-07) | Tier-1 | docs/swiftui/guidelines/g-006-focus-reading-order.md |
| G-007 | Accessibility actions and custom actions | P1 | Accepted | Accepted | Tier-1 documentation + structured doc QA (2026-03-07) | Tier-1 | docs/swiftui/guidelines/g-007-accessibility-actions.md |
| G-008 | Custom controls and accessibility representation | P1 | Accepted | Accepted | Tier-1 documentation + structured doc QA (2026-03-07) | Tier-1 | docs/swiftui/guidelines/g-008-custom-controls-representation.md |
| G-009 | Rotors: when and why | P1 | Accepted | Accepted | Tier-1 documentation + structured doc QA (2026-03-07) | Tier-1 | docs/swiftui/guidelines/g-009-rotors-when-and-why.md |
| G-010 | Dynamic Type and layout resilience | P0 | Accepted | Accepted | Tier-1 documentation + structured doc QA (2026-03-07) | Tier-1 | docs/swiftui/guidelines/g-010-dynamic-type-layout-resilience.md |
| G-011 | Color/contrast and avoid color-only semantics | P0 | Accepted | Accepted | Tier-1 documentation + structured doc QA (2026-03-07) | Tier-1 | docs/swiftui/guidelines/g-011-color-contrast-non-color-cues.md |
| G-012 | Reduced Motion handling | P1 | Accepted | Accepted | Tier-1 documentation + structured doc QA (2026-03-07) | Tier-1 | docs/swiftui/guidelines/g-012-reduced-motion.md |
| G-013 | Modal/sheet focus containment | P1 | Accepted | Accepted | Tier-1 documentation + structured doc QA (2026-03-07) | Tier-1 | docs/swiftui/guidelines/g-013-modal-sheet-focus-containment.md |
| G-014 | Lists/forms/toggles/sliders/complex rows | P1 | Accepted | Accepted | Tier-1 documentation + structured doc QA (2026-03-07) | Tier-1 | docs/swiftui/guidelines/g-014-lists-forms-complex-rows.md |
| G-015 | Media captions/audio descriptions/controls | P2 | Accepted | Accepted | Tier-1 documentation + structured doc QA (2026-03-07) | Tier-1 | docs/swiftui/guidelines/g-015-media-captions-audio-descriptions.md |

## Definition of Done (Per Guideline)

- Includes completed sections from `docs/core/templates/guideline-template.md`.
- Has at least one Tier-1 citation from `docs/core/sources/registry.md`.
- Has explicit test steps (Inspector + VoiceOver minimum).
- Includes at least one concrete do/don't example.
