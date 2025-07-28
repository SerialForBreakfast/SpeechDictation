#!/bin/bash

# Emoji Remover Script
# Recursively removes emoji characters from .txt, .md, .sh, and .swift files
# Usage: ./strip_emojis.sh /path/to/directory

set -e

TARGET_DIR="${1:-.}"  # Default to current dir if no argument passed

if [[ ! -d "$TARGET_DIR" ]]; then
  echo "Error: Directory not found: $TARGET_DIR"
  exit 1
fi

echo "Stripping emojis in: $TARGET_DIR"

# Unicode emoji ranges (partial coverage of all standard emoji ranges)
EMOJI_REGEX="[\\x{1F600}-\\x{1F64F}]|[\\x{1F300}-\\x{1F5FF}]|[\\x{1F680}-\\x{1F6FF}]|[\\x{1F1E6}-\\x{1F1FF}]|[\\x{2600}-\\x{26FF}]|[\\x{2700}-\\x{27BF}]|[\\x{1F900}-\\x{1F9FF}]|[\\x{1FA70}-\\x{1FAFF}]"

# Find target files and clean them
find "$TARGET_DIR" \( -name "*.txt" -o -name "*.md" -o -name "*.sh" -o -name "*.swift" \) | while read -r file; do
  # Use perl to check for emojis to avoid grep -P dependency on macOS.
  if perl -ne 'if (/'"$EMOJI_REGEX"'/) { $m=1; last }; END { exit !$m }' "$file"; then
    echo "Removing emojis from: $file"
    perl -CSD -i -pe "s/$EMOJI_REGEX//g" "$file"
  fi
done

echo "Emoji cleanup complete."