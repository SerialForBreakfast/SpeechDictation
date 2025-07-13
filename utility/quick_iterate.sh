#!/bin/bash

# SpeechDictation iOS - Quick Iteration Script
# Optimized for rapid development cycles with minimal output
# Usage: ./utility/quick_iterate.sh [--verbose] [--clean]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_SCRIPT="$SCRIPT_DIR/build_and_test.sh"

# Parse arguments
VERBOSE=""
CLEAN=""
ENABLE_UI_TESTS=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose)
            VERBOSE="--verbose"
            shift
            ;;
        --clean)
            CLEAN="--clean"
            shift
            ;;
        --enableUITests)
            ENABLE_UI_TESTS="--enableUITests"
            shift
            ;;
        *)
            echo "Usage: $0 [--verbose] [--clean] [--enableUITests]"
            exit 1
            ;;
    esac
done

echo "Starting quick iteration cycle..."
echo "Timestamp: $(date)"
echo ""

# Run build and test with simulator target
"$BUILD_SCRIPT" --simulator $VERBOSE $CLEAN $ENABLE_UI_TESTS

# Quick summary
echo ""
echo "📊 Quick Summary:"
echo "✅ Build completed"
echo "✅ Tests executed"
echo "📄 Full report generated in build/reports/"
echo ""
echo "🔄 Ready for next iteration!" 