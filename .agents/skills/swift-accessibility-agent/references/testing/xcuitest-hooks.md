# XCUITest Hooks for Accessibility Regression Checks

Last updated: 2026-03-07
Scope: lightweight automated assertions that complement manual and inspector audits.

## Intent

XCUITest cannot fully validate VoiceOver announcements, rotor behavior, or nuanced focus semantics.
Use it as a guardrail for deterministic regressions in labels, values, identifiers, and high-level flow visibility.

## What To Automate Reliably

- Existence of key controls using accessibility identifiers.
- Presence of critical user-facing labels for top-priority controls.
- Basic state transitions reflected in visible labels/values.
- Modal entry/exit flow checks (presented element exists; anchor element exists after dismiss).

## Suggested Hook Patterns

### Pattern 1: Critical Control Presence

- Assert key screen controls exist by stable identifiers.
- Fail fast when an expected control is missing.

### Pattern 2: High-Risk Label Regression

- Assert text of a small set of user-critical controls/messages.
- Keep assertions focused; avoid brittle full-screen text snapshots.

### Pattern 3: Stateful Control Updates

- Trigger toggle/slider/selection actions.
- Assert resulting value/state text changes.

### Pattern 4: Modal Focus Proxy

- Present modal/sheet and assert modal title/primary action exists.
- Dismiss modal and assert trigger anchor exists and is hittable.

## Limits and Assumptions

- XCUITest does not guarantee VoiceOver-spoken output parity.
- Rotor navigation and assistive-tech interaction models still require manual validation.
- Passing XCUITests does not replace Accessibility Inspector audits.

## Recommended CI Gate

1. Run a compact accessibility smoke test suite on every PR.
2. Require manual VoiceOver + Inspector pass for releases and large UI refactors.
3. Track failures against guideline IDs where possible (G-001..G-015 / future UIKit IDs).
