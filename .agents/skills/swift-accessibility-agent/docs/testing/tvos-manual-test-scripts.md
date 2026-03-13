# tvOS Manual Accessibility Test Scripts

Last updated: 2026-03-07
Scope: tvOS focus-first interfaces, media-centric flows, and remote-driven interaction.

## Preconditions

- Test on Apple TV hardware when possible; simulator is acceptable for smoke checks.
- Enable VoiceOver for spoken-output validation.
- Verify Reduce Motion variants where focus animations are used.

## Script 1: Focus Reachability Smoke

Pass criteria:
- Every primary action is reachable through directional focus.
- No dead-end focus states or trapped loops.

Steps:
1. Launch app and confirm initial focus lands on a meaningful control.
2. Navigate each major screen using remote directional inputs only.
3. Verify focus can move to and from all primary controls.
4. Record any controls that cannot be reached from one or more directions.

## Script 2: Modal Focus Containment and Restore

Pass criteria:
- Modal focus is contained while active.
- Focus restores to a logical anchor when dismissed.

Steps:
1. Open each modal/sheet from at least two entry points.
2. Confirm focus enters modal primary control.
3. Confirm background controls are not accidentally focusable.
4. Dismiss modal; confirm focus returns to launch anchor or documented fallback.

## Script 3: Media Playback Control Semantics

Pass criteria:
- Transport controls are discoverable and accurately announced.
- Playback state updates are reflected in spoken output.

Steps:
1. Start playback and move focus through transport controls.
2. Trigger play/pause/seek and confirm state announcements.
3. Change captions/audio options and confirm selected state is clear.

## Script 4: Search/Filter State Clarity

Pass criteria:
- Active query/filter state is discoverable and understandable.

Steps:
1. Apply filters and update search query.
2. Confirm control labels/values reflect active criteria.
3. Confirm result updates remain semantically stable after refresh.

## Script 5: Contrast and Non-Color Cue Validation

Pass criteria:
- Critical state is not color-only.
- Focus indicators remain clear across common backgrounds.

Steps:
1. Check representative screens with varied artwork/video backgrounds.
2. Validate selected/error/disabled states have non-color cues.
3. Verify readable contrast for key text and controls.

## Minimum PR Evidence

- One short note per executed script with pass/fail status.
- At least one screenshot per failing case with affected guideline ID(s).
