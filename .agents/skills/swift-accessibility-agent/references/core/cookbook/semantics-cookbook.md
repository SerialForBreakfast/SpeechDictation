# Semantics Cookbook (Canonical Recipes)

Last updated: 2026-03-07

## Recipe 1: Icon-Only Button

Goal: never ship unlabeled icon controls.

Checklist:
- Provide explicit accessibility label.
- Keep label action-oriented.
- Add hint only if behavior is non-obvious.

## Recipe 2: Compound Row With Single Action

Goal: ensure row semantics are concise.

Checklist:
- Use grouping strategy intentionally (`combine` for single-action rows).
- Include row value/state when relevant.

## Recipe 3: Compound Row With Multiple Actions

Goal: preserve discoverability of each action.

Checklist:
- Prefer `contain` when child actions are independently actionable.
- Ensure child controls have distinct labels.

## Recipe 4: Custom Visual/Chart

Goal: expose non-standard visuals accessibly.

Checklist:
- Provide synthetic accessible children where needed.
- Or provide alternate semantic representation.
- Ensure values and ordering are meaningful.

## Recipe 5: Modal Focus Lifecycle

Goal: deterministic focus on open/close.

Checklist:
- Define initial focus target.
- Define restore focus anchor.
- Verify behavior via manual walkthrough.

## Recipe 6: Interop Boundary (Host + Embedded)

Goal: avoid semantics loss at framework boundaries.

Checklist:
- Assign focus owner and semantics owner.
- Validate no duplicate or dropped labels.
- Confirm UI-test querying strategy.
