# SwiftAccessibilityAgent

Source-driven accessibility guidance for SwiftUI, UIKit, tvOS, macOS, and visionOS, designed for both human developers and AI coding agents.

Current version: `0.2.2`

## What This Is

SwiftAccessibilityAgent is a documentation-first accessibility knowledge base for Apple-platform UI development.

It provides:
- Tiered source governance (Apple-first platform truth)
- Implementation guidance for SwiftUI/UIKit/AppKit and interop boundaries
- Testing and regression-triage workflows
- Agent-ready manifests and runtime loading rules
- Explicit routing and trust-language suitable for evaluation

## Who This Is For

- Engineers building Apple-platform UI
- Teams running accessibility-focused PR reviews
- AI agents generating or modifying UI code

## Install As a Skill

Most users should install this skill from the root of the project where they want their agent to use it.

Example:

```bash
cd /path/to/your/project
```

If you install it there, the skill is available to that project without affecting every other project on your machine.

### Before You Start

You need:
- Terminal access on macOS
- Node.js installed (`node` and `npx`)
- Git available (`git`)
- Internet access to download the skill

Quick check:

```bash
git --version
node --version
npx --version
```

If all commands print a version number, continue to the install step.

### If You Do Not Have Homebrew

Homebrew is the easiest way for many macOS users to install Node.js.

Official Homebrew install command:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

After Homebrew finishes, open a new Terminal window or follow the PATH instructions it prints.

### Install Node.js

Recommended on macOS if you use Homebrew:

```bash
brew install node
```

If you do not want to use Homebrew, install the official Node.js LTS package from:

- [nodejs.org/download](https://nodejs.org/en/download)

Then confirm Node.js is available:

```bash
node --version
npx --version
```

### Install in Your Project Directory

From the root of the app or repository where you want the skill available:

```bash
npx skills add https://github.com/SerialForBreakfast/SwiftAccessibilityAgent --skill swift-accessibility-agent --agent codex --yes
```

### Verify Installation

First, confirm the CLI sees the skill:

```bash
npx skills list
```

Then confirm the files were installed in the current project:

```bash
find .agents/skills -maxdepth 2 -name SKILL.md 2>/dev/null | grep swift-accessibility-agent
```

Expected project-local installed path:

```text
./.agents/skills/swift-accessibility-agent/SKILL.md
```

If the skill installs correctly but does not appear in the active session immediately, refresh or restart the session.

### What New Users Should Do

1. Open Terminal.
2. `cd` into the project you are actively working on.
3. Make sure `node` and `npx` work.
4. Run the install command once.
5. Verify the skill appears in `npx skills list`.
6. Start or refresh your agent session in that project.

### Optional: Global Install Alternative

Use this only if you want the skill available across multiple projects instead of just one:

```bash
npx skills add https://github.com/SerialForBreakfast/SwiftAccessibilityAgent --skill swift-accessibility-agent --agent codex --global --yes
```

Expected global installed path:

```text
~/.codex/skills/swift-accessibility-agent/SKILL.md
```

## Use With Xcode

`npx skills add ...` remains the first-class install path for this repository.

If you also want to use the same skill content with Xcode's Codex agent, install an Xcode compatibility link from this repository root:

```bash
./scripts/install-for-xcode.sh
```

What this does:
- creates Xcode's Codex customization directory if needed
- creates a symlink from Xcode's Codex directory to this repository
- keeps `SKILL.md`, `agents/openai.yaml`, and `references/` as the single source of truth

Expected Xcode compatibility path:

```text
~/Library/Developer/Xcode/CodingAssistant/codex/swift-accessibility-agent
```

Verify the link:

```bash
ls -la ~/Library/Developer/Xcode/CodingAssistant/codex/swift-accessibility-agent
```

If Xcode is already open, quit and reopen it after running the script.

### Manual Xcode Install

If you do not want to run the helper script, you can create the Xcode compatibility link manually.

From this repository root:

```bash
mkdir -p ~/Library/Developer/Xcode/CodingAssistant/codex
ln -sfn "$(pwd)" ~/Library/Developer/Xcode/CodingAssistant/codex/swift-accessibility-agent
```

Then verify:

```bash
ls -la ~/Library/Developer/Xcode/CodingAssistant/codex/swift-accessibility-agent
```

Expected entry files:

```text
~/Library/Developer/Xcode/CodingAssistant/codex/swift-accessibility-agent/SKILL.md
~/Library/Developer/Xcode/CodingAssistant/codex/swift-accessibility-agent/agents/openai.yaml
```

If Xcode is already open, quit and reopen it after creating the link.

### Recommended Xcode Workflow

1. Keep the main install path as `npx skills add ...` for Codex/skills-based workflows.
2. From this repository root, either run `./scripts/install-for-xcode.sh` or create the link manually.
3. Restart Xcode.
4. Open your project in Xcode and use the Codex agent there.

### Troubleshooting

If `node` or `npx` is not found:
- Install Node.js first, then reopen Terminal.

If `brew` is not found:
- Install Homebrew first, or install Node.js directly from [nodejs.org/download](https://nodejs.org/en/download).

If `git` is not found:
- Install Apple's Command Line Tools when macOS prompts you, then reopen Terminal.

If the install command works but the skill does not appear in your session:
- Refresh or restart the session in the same project directory.

If you accidentally installed globally but wanted project-local behavior:
- Go back to your project directory and run the project-local install command there.

If Xcode does not pick up the compatibility install:
- Confirm `~/Library/Developer/Xcode/CodingAssistant/codex/swift-accessibility-agent/SKILL.md` exists.
- Quit and reopen Xcode.
- Re-run `./scripts/install-for-xcode.sh` from this repository root.

## Quick Start

1. Pick a platform/framework track:
- `references/swiftui/`
- `references/uikit/`
- `references/tvos/`
- `references/macos/`
- `references/visionos/`

2. Load shared core guidance:
- `references/core/sources/registry.md`
- `references/core/technology-map.md`
- `references/core/taxonomy/semantics-checklist.md`

3. Apply guideline + testing artifacts relevant to your change.

## Core Documents

- Agent operating contract: `SKILL.md`
- Version baseline: `VERSION`
- UI metadata: `agents/openai.yaml`
- Runtime manifests: `references/manifests/`
- Versioning strategy: `references/core/versioning-strategy.md`
- Source registry: `references/core/sources/registry.md`
- Architecture principles: `references/core/architecture/architecture-principles.md`
- Decision matrix: `references/core/decision-matrix.md`
- Pattern review rubric: `references/core/pattern-review-rubric.md`
- External landscape references: `references/core/external-landscape.md`
- Semantics cookbook: `references/core/cookbook/semantics-cookbook.md`
- Known issues catalog: `references/core/known-os-issues.md`
- Version matrix: `references/core/version-matrix.md`
- Testing artifacts: `references/testing/`

## Using With AI Agents

1. Load `SKILL.md`.
2. Choose task workflow first (review, improve, implement).
3. Resolve runtime selection through `references/manifests/` (`platform`, `framework`, `task_type`) only as needed.
4. Load only resolved docs and required verification artifacts.

For substantive repository-domain answers, the agent should emit:

- on the first response in a chat, one identity line:
  - `Swift Accessibility Agent (v0.2.2)`
- whenever the answer actually uses repository guidance:
  - a `ROUTING:` line naming the repo docs it used
  - the answer itself
  - a trust footer with `Sources:`, `Freshness:`, and `Assumptions:`

If the answer does not use repository guidance, no `ROUTING:` line is required.
First response example:

```text
Swift Accessibility Agent (v0.2.2)
```

Repository-guided answer example:

```text
ROUTING: [uikit:u-005-grouping-containment.md, core:known-os-issues-workflow.md]

<answer>

Sources: docs/uikit/guidelines/u-005-grouping-containment.md; docs/core/known-os-issues-workflow.md
Freshness: HIGH — current repository guidance supports this answer
Assumptions: none
```

## Evaluation

Promptfoo scaffolding lives in:

- `evals/promptfoo/`

The evaluation model compares:

- `C0`: bare model baseline
- `C1`: agent identity + routing protocol
- `C2`: agent + injected reference docs

Primary checks:

- first-turn identity includes `Swift Accessibility Agent (v0.2.2)`
- repository-guided answers include `ROUTING:`
- routing names the expected repository file
- repository-guided answers include `Sources:`, `Freshness:`, and `Assumptions:`

## Validation Checklist

- `SKILL.md` exists at installed skill root.
- `agents/openai.yaml` exists.
- Manifest and reference paths in `SKILL.md` resolve.
- Skill appears in session available skills list.
- Skill triggers by name: `swift-accessibility-agent`.

## Source Governance

- Tier-1: Apple platform truth
- Tier-2: High-quality implementation references
- Tier-3: Discovery/context only
- If sources conflict, Tier-1 wins

## License

MIT. See `LICENSE`.
