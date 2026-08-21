# Promptfoo Evaluation

Current baseline: `0.2.2`

## Purpose

Measure whether:

- agent identity survives
- routing is visible and correct
- injected repo references improve answer quality

## Configs

- `C0`: bare model baseline
- `C1`: skill identity + routing protocol, no injected docs
- `C2`: same as `C1`, plus selected repo references injected inline

Expected interpretation:

- `C0` is the control and will often fail routing or source-disclosure assertions
- `C1` tests identity and routing behavior without repo excerpts
- `C2` tests whether injected repo excerpts improve routing-backed answer quality

## Files

- `promptfooconfig.yaml`
- `prompts/c0.txt`
- `prompts/c1.txt`
- `prompts/c2.txt`
- `gold-prompts.md`

## Suggested Run

```bash
promptfoo eval -c evals/promptfoo/promptfooconfig.yaml
```

## Minimum Assertions

- first-turn identity includes `Swift Accessibility Agent (v0.2.2)`
- repository-guided answers include `ROUTING:`
- routing names the expected repo doc
- repository-guided answers include `Sources:`, `Freshness:`, and `Assumptions:`

## C2 Injection Note

The scaffold injects short repo-derived excerpts inline for `C2`.
If you expand coverage, keep those excerpts short, stable, and directly tied to the expected route.

## Gold Prompt Authoring Rules

Write prompts as close to real developer questions as possible:

- prefer natural task language over internal backlog titles
- allow common Apple framework terms (`SwiftUI`, `UITableView`, `NSWindow`, `NSHostingView`, `VoiceOver`, `tvOS`)
- avoid seeding the prompt with the exact expected answer
- avoid copying the repository's own rule language into the prompt
- cover both broad questions and concrete bug-like questions

The goal is not just answer correctness. It is to measure whether the agent can:

- recognize the domain from real developer language
- route to the right repository guidance
- surface that routing visibly
- answer with source-backed reasoning

Also verify negative cases:

- identity should not repeat on every later turn
- `ROUTING:` should not appear when the answer does not rely on repository guidance
- `Sources:`, `Freshness:`, and `Assumptions:` should not appear for non-repository answers
- common Apple UI terms alone (`UILabel`, `UIButton`, `NSWindow`, `SwiftUI`) should not trigger this skill unless the user is actually asking about accessibility
