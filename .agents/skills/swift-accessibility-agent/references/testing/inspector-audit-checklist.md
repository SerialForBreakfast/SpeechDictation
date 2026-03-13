# Accessibility Inspector Audit Checklist

Last updated: 2026-03-07
Primary tool: Xcode Accessibility Inspector

## How To Use

1. Launch app in simulator/device.
2. Open Accessibility Inspector and target the running app.
3. Traverse each screen and apply this checklist.
4. Record pass/fail and notes per item.

## Checklist

### Element Semantics

- [ ] Every meaningful interactive element has non-empty label.
- [ ] Stateful controls expose current value.
- [ ] Hints are present only when they add missing action context.
- [ ] Role/traits align with actual behavior (button, header, adjustable, selected, etc.).
- [ ] Custom actions are exposed for non-obvious interactions.

### Tree Structure and Grouping

- [ ] Decorative elements are hidden from accessibility traversal.
- [ ] Grouped rows combine related text without hiding required child actions.
- [ ] Containers do not flatten unrelated child semantics.

### Focus and Navigation

- [ ] Reading/focus order follows task flow.
- [ ] No hidden overlays/modals leave background controls focusable.
- [ ] Dismissed modal returns focus to logical trigger anchor.

### Visual Accessibility Coverage

- [ ] Critical text and controls remain readable at large text sizes.
- [ ] Important status/error/selection cues are not color-only.
- [ ] Reduced-motion flows still provide clear state change outcomes.

## Minimum Audit Pass Criteria

- Zero unlabeled interactive controls on tested screens.
- Zero blocking focus-order defects in primary user flows.
- Zero modal focus-containment defects.
- No P0 semantic regressions (label/value/role/action on core controls).

## Severity Guidance

- P0: blocks task completion or causes high-risk mis-action.
- P1: materially degrades usability but workaround exists.
- P2: minor clarity or consistency issue.
