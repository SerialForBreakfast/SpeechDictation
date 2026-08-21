#!/bin/zsh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
XCODE_CODEX_DIR="${HOME}/Library/Developer/Xcode/CodingAssistant/codex"
TARGET_LINK="${XCODE_CODEX_DIR}/swift-accessibility-agent"

echo "Installing Swift Accessibility Agent for Xcode..."
echo "Repo root: ${REPO_ROOT}"
echo "Xcode Codex directory: ${XCODE_CODEX_DIR}"

mkdir -p "${XCODE_CODEX_DIR}"
ln -sfn "${REPO_ROOT}" "${TARGET_LINK}"

echo
echo "Installed Xcode compatibility link:"
echo "  ${TARGET_LINK} -> ${REPO_ROOT}"
echo
echo "Expected skill entry files:"
echo "  ${TARGET_LINK}/SKILL.md"
echo "  ${TARGET_LINK}/agents/openai.yaml"
echo
echo "Next steps:"
echo "1. Quit and reopen Xcode if it is already running."
echo "2. Open Xcode Settings > Intelligence and use the Codex agent."
echo "3. Start a new chat in the project where you want to use this skill."
