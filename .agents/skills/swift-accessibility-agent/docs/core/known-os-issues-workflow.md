# Known OS Issues Workflow

Last updated: 2026-03-07

## Purpose

Define how known accessibility regressions are added, verified, and retired.

## Add Criteria

Create a new entry when all are true:
- Symptom is reproducible or strongly corroborated by trusted sources.
- Impact is user-visible (focus/semantics/announcement/performance/testability).
- At least one source link is available from registry IDs.

## Required Entry Data

- ID (`AX-BUG-###`)
- Platform/OS range
- Affected framework(s)
- Symptom class
- Version status fields:
  - `introduced_in`
  - `affected_range`
  - `fixed_in`
  - `status`
  - `evidence_confidence`
- Detection signals
- Repro steps (if known)
- Mitigation/workaround status
- Source link IDs
- Last verified date

## Verification Cadence

- Quarterly baseline review.
- Additional review after each major OS release.
- Immediate review when severe user-facing regression is reported.

## Mitigation Claim Rules

- Mark workaround as `confirmed` only after local repro + re-test.
- If workaround is anecdotal, mark as `candidate`.
- Never promote a workaround to guideline truth without Tier-1 corroboration.
- If `fixed_in` is claimed, include release-note or equivalent primary evidence in source IDs.

## Retirement Rules

Retire or downgrade an entry when:
- Issue no longer reproduces on supported OS range.
- Release notes or validated testing confirm resolution.

When retiring:
- Keep historical note with resolved OS version.
- Update related guideline notes and triage playbook references.

## Ownership

- Primary owner: accessibility maintainers.
- Secondary owner: platform track maintainers (iOS/tvOS/macOS/visionOS).
