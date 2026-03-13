# macOS Manual Accessibility Test Scripts

Last updated: 2026-03-07
Scope: macOS SwiftUI/AppKit interfaces, keyboard-first workflows, and multi-window/modal behavior.

## Preconditions

- Test with VoiceOver enabled for spoken-output checks.
- Test with keyboard-only navigation for critical flows.
- Include at least one flow that crosses SwiftUI/AppKit boundaries if interop exists.

## Script 1: Keyboard Traversal Completeness

Pass criteria:
- Critical flows are keyboard-completable.
- Focus order is predictable and matches task structure.

Steps:
1. Start from app launch without pointer input.
2. Traverse each key workflow using keyboard navigation only.
3. Confirm primary and secondary actions are reachable and operable.
4. Record any unreachable controls or confusing order jumps.

## Script 2: VoiceOver Semantic Accuracy

Pass criteria:
- Controls announce clear role, label, and state.
- Repeated controls are distinguishable in context.

Steps:
1. Traverse each changed screen with VoiceOver.
2. Validate row/list/table/outline announcements include state context.
3. Trigger state changes and confirm announcements update accordingly.

## Script 3: Modal/Window Focus Lifecycle

Pass criteria:
- Focus is contained in active modal/window context.
- Focus restores to logical anchor on close.

Steps:
1. Open sheets/panels/dialogs from representative entry points.
2. Validate focus entry target on presentation.
3. Dismiss context and verify focus restoration behavior.

## Script 4: Interop Boundary Regression Check

Pass criteria:
- Hosting boundaries preserve semantics and focus behavior.

Steps:
1. Identify one SwiftUI-in-AppKit boundary and one AppKit custom-view area.
2. Compare semantics before/after interaction transitions.
3. Confirm no role/label/action loss across boundaries.

## Script 5: Contrast and Non-Color Cue Coverage

Pass criteria:
- State is understandable without color-only cues.
- Critical controls remain readable in varied window contexts.

Steps:
1. Validate selected/error/warning states include text/icon/shape reinforcement.
2. Confirm readability in toolbars, sidebars, and overlays.
3. Confirm no critical state relies solely on tint/opacity differences.

## Minimum PR Evidence

- Script pass/fail results attached to PR notes.
- Inspector evidence or screenshots for any regressions.
- Linked guideline IDs for each observed issue.
