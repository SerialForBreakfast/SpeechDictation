#!/usr/bin/env bash
set -euo pipefail

# Runs ONLY the UI test bundle using xcodebuild's -only-testing filter.
# The identifier format for filtering is TestTarget[/TestClass[/TestMethod]]. 

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
XCODEPROJ="${XCODEPROJ:-$REPO_ROOT/SpeechDictation.xcodeproj}"
SCHEME="${SCHEME:-SpeechDictation}"
DESTINATION="${DESTINATION:-platform=iOS Simulator,name=iPhone 15,OS=latest}"

DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-$REPO_ROOT/.derivedData_uitests}"
RESULTS_DIR="${RESULTS_DIR:-$REPO_ROOT/TestResults}"
mkdir -p "$RESULTS_DIR"

STAMP="$(date +%Y%m%d_%H%M%S)"
RESULT_BUNDLE_PATH="$RESULTS_DIR/UITests_$STAMP.xcresult"

echo "[integrationTests] project=$XCODEPROJ"
echo "[integrationTests] scheme=$SCHEME"
echo "[integrationTests] destination=$DESTINATION"
echo "[integrationTests] resultBundlePath=$RESULT_BUNDLE_PATH"

xcodebuild \
  -project "$XCODEPROJ" \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  -resultBundlePath "$RESULT_BUNDLE_PATH" \
  test \
  -only-testing:SpeechDictationUITests

echo "[integrationTests] Done. xcresult: $RESULT_BUNDLE_PATH"