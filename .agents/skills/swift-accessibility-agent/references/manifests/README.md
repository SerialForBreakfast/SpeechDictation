# Runtime Manifests (Low-Token Loading)

Purpose: let agents resolve a minimal doc set before loading long-form guidance.

## Files

- `axes.json`: allowed platform/framework/task values.
- `routes.json`: platform+framework route to default guideline/backlog paths.
- `task-presets.json`: task-specific extra docs to load.
- `platform-presets.json`: platform-specific test docs to load.
- `select-example.json`: concrete selection-to-load examples.
- `decision-rules.json`: machine-readable alternative-selection rules.
- `security-policy.json`: machine-readable execution and prompting guardrails.
- `pattern-signals.json`: machine-readable good/risky/bad pattern classification signals.
- `core.json`: always-on baseline docs and strict load order.

## Resolution Steps

1. Pick `platform`, `framework`, and `task_type`.
2. Load `core.json` first.
3. Resolve route in `routes.json`.
4. Add platform extras from `platform-presets.json`.
5. Add task extras from `task-presets.json`.
6. Load only listed files until blocked.
