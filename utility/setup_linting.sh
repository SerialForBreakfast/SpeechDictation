#!/bin/bash

# setup_linting.sh
# Script to install and configure SwiftLint for emoji detection and other code quality rules

set -e

echo "🔧 Setting up SwiftLint for SpeechDictation project..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    print_error "Homebrew is not installed. Please install Homebrew first:"
    echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    exit 1
fi

print_info "Homebrew found ✓"

# Install SwiftLint if not already installed
if ! command -v swiftlint &> /dev/null; then
    print_info "Installing SwiftLint..."
    if brew install swiftlint; then
        print_info "SwiftLint installed successfully ✓"
    else
        print_error "Failed to install SwiftLint"
        exit 1
    fi
else
    print_info "SwiftLint already installed ✓"
    # Update to latest version
    print_info "Updating SwiftLint to latest version..."
    brew upgrade swiftlint || print_warning "SwiftLint is already up to date"
fi

# Verify SwiftLint version
SWIFTLINT_VERSION=$(swiftlint version)
print_info "SwiftLint version: $SWIFTLINT_VERSION"

# Run SwiftLint on the project to test the configuration
print_info "Testing SwiftLint configuration..."
cd "$(dirname "$0")/.."

if swiftlint lint --config .swiftlint.yml --reporter xcode; then
    print_info "SwiftLint configuration is valid ✓"
else
    print_warning "SwiftLint found issues. Review the output above."
fi

# Create a pre-commit hook to run SwiftLint automatically
HOOK_PATH=".git/hooks/pre-commit"
print_info "Setting up pre-commit hook..."

cat > "$HOOK_PATH" << 'EOF'
#!/bin/bash

# Pre-commit hook to run SwiftLint

# Run SwiftLint on staged Swift files
git diff --cached --name-only --diff-filter=d | grep -E '\.(swift)$' | while read filename; do
    if [[ -e "${filename}" ]]; then
        swiftlint lint --path "${filename}" --config .swiftlint.yml --reporter emoji
        if [ $? -ne 0 ]; then
            echo "❌ SwiftLint failed on ${filename}"
            echo "Please fix the linting errors before committing."
            exit 1
        fi
    fi
done

echo "✅ SwiftLint passed for all staged Swift files"
EOF

# Make the hook executable
chmod +x "$HOOK_PATH"
print_info "Pre-commit hook created ✓"

# Add SwiftLint build phase script for Xcode
BUILD_SCRIPT_PATH="utility/xcode_swiftlint_build_phase.sh"
print_info "Creating Xcode build phase script..."

cat > "$BUILD_SCRIPT_PATH" << 'EOF'
#!/bin/bash

# Xcode Build Phase Script for SwiftLint
# Add this as a "New Run Script Phase" in your Xcode target's Build Phases

if [[ "$(uname -m)" == arm64 ]]; then
    export PATH="/opt/homebrew/bin:$PATH"
fi

if which swiftlint > /dev/null; then
    swiftlint lint --config "${SRCROOT}/.swiftlint.yml"
else
    echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
fi
EOF

chmod +x "$BUILD_SCRIPT_PATH"
print_info "Xcode build phase script created ✓"

# Test the emoji detection
print_info "Testing emoji detection rules..."
TEST_FILE="/tmp/emoji_test.swift"
cat > "$TEST_FILE" << 'EOF'
// Test file with emojis
class TestClass {
    let message = "Hello 👋 World"  // This should trigger a warning
    
    // This comment has an emoji 🚀 and should trigger an error
    func someFunction() {
        print("No emojis here") // This is fine
    }
}
EOF

print_info "Running emoji detection test..."
if swiftlint lint --path "$TEST_FILE" --config .swiftlint.yml --reporter emoji; then
    print_warning "Emoji detection test completed. Check if emojis were flagged above."
else
    print_info "Emoji detection is working - errors were found as expected ✓"
fi

# Clean up test file
rm -f "$TEST_FILE"

print_info "🎉 SwiftLint setup complete!"
print_info ""
print_info "Next steps:"
print_info "1. Add the build phase script to your Xcode project:"
print_info "   - Open your project in Xcode"
print_info "   - Select your target"
print_info "   - Go to Build Phases"
print_info "   - Click '+' and add 'New Run Script Phase'"
print_info "   - Copy the contents of: utility/xcode_swiftlint_build_phase.sh"
print_info ""
print_info "2. SwiftLint will now:"
print_info "   - Run automatically on git commits (pre-commit hook)"
print_info "   - Run during Xcode builds (if you add the build phase)"
print_info "   - Flag any emoji usage as errors/warnings"
print_info ""
print_info "3. To run SwiftLint manually:"
print_info "   swiftlint lint --config .swiftlint.yml"
print_info ""
print_info "4. To auto-fix some issues:"
print_info "   swiftlint --fix --config .swiftlint.yml" 