# Accessibility Inspector Audit Checklist

Last updated: 2026-03-12
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

### Metadata To Capture Per High-Risk Element

Record these fields for elements involved in regressions, dense screens, or custom controls:

- [ ] Element path or container lineage (screen > section > row > control).
- [ ] Label, value, hint, role/traits.
- [ ] Available custom actions and action names.
- [ ] Focus order position relative to neighboring elements.
- [ ] Landmark/heading eligibility where rotor navigation matters.
- [ ] Selected, expanded, modal, or disabled state where applicable.

### Tree Structure and Grouping

- [ ] Decorative elements are hidden from accessibility traversal.
- [ ] Grouped rows combine related text without hiding required child actions.
- [ ] Containers do not flatten unrelated child semantics.
- [ ] Container ownership is clear: host container vs embedded subtree.
- [ ] Dense sections expose meaningful region or heading structure when applicable.

### Focus and Navigation

- [ ] Reading/focus order follows task flow.
- [ ] No hidden overlays/modals leave background controls focusable.
- [ ] Dismissed modal returns focus to logical trigger anchor.
- [ ] Core tasks remain completable through linear navigation.
- [ ] Rotor/action-menu acceleration is additive rather than required for primary tasks.

### Transition and Announcement Capture

Use before/after snapshots for dynamic flows instead of a single static inspection point:

- [ ] Capture state before interaction.
- [ ] Capture state immediately after interaction.
- [ ] Record changed value/trait/action availability.
- [ ] Note whether announcement or focus destination matches expected result.

### Visual Accessibility Coverage

- [ ] Critical text and controls remain readable at large text sizes.
- [ ] Important status/error/selection cues are not color-only.
- [ ] Reduced-motion flows still provide clear state change outcomes.

### Media and AV-Specific Metadata

For playback surfaces, capture more than control presence:

- [ ] Play/pause state is exposed semantically.
- [ ] Timeline value includes meaningful position context.
- [ ] Duration or progress context is available when relevant.
- [ ] Stream kind is captured when it changes user expectations (live, on-demand, local, ad segment).
- [ ] Seekability and skip constraints are captured when transport behavior is limited.
- [ ] Buffering/loading/stalled state is captured when it changes control availability or announcements.
- [ ] Playback rate, Picture in Picture, and external playback state are captured when supported.
- [ ] Caption/subtitle availability is exposed.
- [ ] Selected caption/audio option state is exposed with option name when changeable.
- [ ] Supplemental inspection snapshot is captured when underlying stream state is intentionally richer than the spoken response.
- [ ] Overlay controls do not obscure or duplicate accessible media controls.

## Minimum Audit Pass Criteria

- Zero unlabeled interactive controls on tested screens.
- Zero blocking focus-order defects in primary user flows.
- Zero modal focus-containment defects.
- No P0 semantic regressions (label/value/role/action on core controls).

## Evidence Record Template

Use this compact structure when an Inspector finding needs more than pass/fail:

- Screen:
- Element/container path:
- Before state:
- After state:
- Label/value/hint/traits:
- Actions available:
- Rotor/heading context:
- Media state (if applicable):
- Stream kind / transport constraints:
- Supplemental inspection snapshot:
- Expected result:
- Actual result:

## Severity Guidance

- P0: blocks task completion or causes high-risk mis-action.
- P1: materially degrades usability but workaround exists.
- P2: minor clarity or consistency issue.
