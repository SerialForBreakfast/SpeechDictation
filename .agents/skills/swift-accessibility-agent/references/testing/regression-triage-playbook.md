# Accessibility Regression Triage Playbook

Last updated: 2026-03-12
Scope: suspected accessibility regressions across SwiftUI/UIKit/AppKit and OS updates.

## Inputs Required

- Platform and OS build
- Device/simulator details
- Framework layer(s): SwiftUI/UIKit/AppKit/interop
- Repro steps with expected vs actual outcome
- For media incidents: stream kind, transport expectations, selected media options, and current playback/buffering state

## Triage Sequence

1. Reproduce with VoiceOver enabled.
2. Run Accessibility Inspector tree check on affected screen.
3. Capture supplemental inspection snapshot when media or other high-entropy dynamic state is involved.
4. Classify symptom using `docs/core/known-os-issues.md` classes.
5. Check known catalog entries for matching mitigation.
6. Apply workaround candidate and re-run script.
7. Document result and severity.

## Severity Guidance

- Blocker: control missing from accessibility tree, hard focus trap, app hang with accessibility enabled.
- High: wrong role/trait causing action ambiguity; critical state not announced.
- Medium: noisy/duplicate announcements with viable fallback.
- Low: minor wording inconsistencies without task failure.

## Required Documentation Output

- Issue ID and linked symptom class
- Affected OS version range
- Evidence artifacts (Inspector screenshot/tree capture + VoiceOver notes + supplemental inspection snapshot where applicable)
- Mitigation status: confirmed workaround / no workaround
- Source references from registry IDs

## Escalation

Escalate immediately when:
- issue reproduces on latest shipping OS builds
- issue blocks core flow completion
- issue appears to be framework/OS regression outside app logic
