# Versioning Strategy

Last updated: 2026-03-21
Current version: 0.2.2

## Purpose

Keep the skill contract, repository guidance, and evaluation results aligned under one visible version.

## Current Policy

- Skill version: `0.2.2`
- Reference-set version: `0.2.2`
- Evaluation baseline version: `0.2.2`

For now, these versions move together.

## Bump Rules

### Patch (`0.2.x`)

Use for:

- wording clarity
- install and onboarding updates
- typo fixes
- eval additions that do not materially change agent behavior

### Minor (`0.x.0`)

Use for:

- output contract changes
- routing behavior changes
- new platform or domain coverage
- new prompt rules that are likely to change answer behavior
- major additions to repository guidance that materially affect model responses

### Major (`1.0.0` and beyond)

Do not use until the output contract, routing behavior, and repo structure are considered stable enough for broad external adoption.

## Required Version Touchpoints

When the version changes, update:

- `VERSION`
- `SKILL.md` frontmatter
- `SKILL.md` identity declaration
- `README.md`
- `docs/changelog.md`
- promptfoo eval expectations
- runtime manifest version where applicable

## Evaluation Coupling

The eval layer must assert the active version string directly.

Minimum checks:

- first response or identity probe includes `Swift Accessibility Agent (v0.2.2)`
- repository-guided answers include `ROUTING:`
- repository-guided answers include `Sources:`, `Freshness:`, and `Assumptions:`

## Release Baseline

`0.2.2` is the current public version baseline for this repository.
