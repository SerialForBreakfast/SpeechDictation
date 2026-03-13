# Accessibility Pattern Review Rubric (Good vs Bad)

Last updated: 2026-03-07
Scope: SwiftUI/UIKit/AppKit code review and generation checks.

## Purpose

Give agents deterministic criteria to classify accessibility implementation patterns as strong, risky, or unacceptable.

## Rating Scale

- `Good`: aligns with platform semantics and verification expectations.
- `Risky`: works in some cases but likely to regress across versions or contexts.
- `Bad`: creates user-visible accessibility defects or blocks assistive-tech workflows.

## Pattern Categories

### 1) Labels and Naming

Good:
- Every interactive element has a meaningful, localized label.
- Icon-only controls use explicit labels.

Risky:
- Labels are present but overly generic (e.g., repeated "More" controls).

Bad:
- Interactive elements without labels.
- Duplicate ambiguous names in same interaction scope.

### 2) Values and Stateful Semantics

Good:
- Stateful controls expose current values and selection/on-off status.

Risky:
- State is exposed in some paths but missing after dynamic updates.

Bad:
- State changes are visual-only; no semantic value update.

### 3) Grouping and Containment

Good:
- Compound rows explicitly choose grouping strategy with intent.

Risky:
- Grouping behavior depends on incidental hierarchy.

Bad:
- Over-grouping hides actionable children.
- Under-grouping creates noisy, contextless announcements.

### 4) Focus and Reading Order

Good:
- Focus order follows task flow and modal lifecycle is deterministic.

Risky:
- Works in steady state but fails after overlays/sheets/async updates.

Bad:
- Focus traps, dead ends, or random jumps.

### 5) Custom Controls and Complex Visuals

Good:
- Custom visuals provide semantic children or alternate representation.

Risky:
- Partial semantics provided without action/state parity.

Bad:
- Complex visuals exposed as unlabeled generic containers.

### 6) Interop Boundaries (SwiftUI/UIKit/AppKit)

Good:
- Host/subtree ownership for focus vs semantics is explicitly documented.

Risky:
- Ownership implied but not enforced in tests.

Bad:
- Mixed stack with no ownership model; semantics lost or duplicated.

### 7) Verification Quality

Good:
- Inspector + VoiceOver evidence included; smoke automation where relevant.

Risky:
- One validation mode only.

Bad:
- No verification evidence for accessibility-affecting change.

## Scoring Guidance

- Start score: 100
- Subtract 10 for each risky finding.
- Subtract 25 for each bad finding.
- Any bad finding in categories 1, 4, or 7 => auto-fail.

## Review Output Format (Agent)

1. Classification: `Good` / `Risky` / `Bad`
2. Findings by category with severity.
3. Required fixes before merge.
4. Verification plan tied to impacted categories.
