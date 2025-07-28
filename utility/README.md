# SpeechDictation iOS - Utility Scripts

This folder contains automation scripts for building, testing, and validating the SpeechDictation iOS project.

## Scripts Overview

### `build_and_test.sh` - Comprehensive Build & Test Automation
**Primary script for full project validation with detailed reporting.**

**Features:**
- **Prerequisite Validation** - Checks Xcode, simulators, project structure
- **Build Automation** - Clean builds with error handling
- **Test Execution** - Unit tests and UI tests with detailed reporting
- **Performance Metrics** - Build time, test counts, project size
- **Error Handling** - Graceful failure with debugging information
- **Timestamped Reports** - Detailed logs in `build/reports/`
- **Simulator Caching** - Remembers last used simulator for faster subsequent runs
- **Optimized Boot Process** - Faster simulator boot with improved status checking
- **Cache Management** - Clear simulator cache when needed with `--cache-clear`

**Usage:**
```bash
# Basic run (simulator)
./utility/build_and_test.sh

# Verbose output
./utility/build_and_test.sh --verbose

# Clean build
./utility/build_and_test.sh --clean

# Device testing (requires connected device)
./utility/build_and_test.sh --device

# Simulator with specific settings
./utility/build_and_test.sh --simulator --verbose --clean

# Enable UI tests (disabled by default)
./utility/build_and_test.sh --enableUITests

# Full validation with UI tests
./utility/build_and_test.sh --clean --enableUITests
```

### `quick_iterate.sh` - Rapid Development Cycle
**Optimized for fast iteration during development.**

**Features:**
- **Fast Execution** - Minimal output, quick feedback
- **Simulator Focused** - Uses iPhone 15 simulator by default
- **Development Optimized** - Skips UI tests for speed (can be enabled)
- **Quick Summary** - Essential status information only

**Usage:**
```bash
# Quick iteration
./utility/quick_iterate.sh

# Verbose iteration
./utility/quick_iterate.sh --verbose

# Clean iteration
./utility/quick_iterate.sh --clean

# Quick iteration with UI tests
./utility/quick_iterate.sh --enableUITests
```

## Report Structure

### Generated Files
```
build/
├── reports/
│   └── build_test_report_YYYYMMDD_HHMMSS.txt
├── xcodebuild.log
├── test.log
├── ui_test.log (only when --enableUITests is used)
└── derived_data/
```

### Report Contents
1. **System Information** - macOS, Xcode versions, available simulators
2. **Build Results** - Success/failure with timing
3. **Test Results** - Unit test summary with pass/fail counts
4. **UI Test Results** - UI test summary (only when enabled)
5. **Performance Metrics** - Build time, project size, disk space
6. **Error Details** - Full error context for debugging
7. **Summary** - Overall status and log file locations

## Integration with Development Workflow

### For Daily Development
```bash
# Quick validation after changes
./utility/quick_iterate.sh

# Full validation before commits
./utility/build_and_test.sh --clean
```

### For CI/CD Integration
```bash
# Production validation
./utility/build_and_test.sh --device --verbose

# Automated testing
./utility/build_and_test.sh --simulator

# Full validation including UI tests
./utility/build_and_test.sh --simulator --enableUITests
```

### For Debugging
```bash
# Verbose output for troubleshooting
./utility/build_and_test.sh --verbose --clean

# Check specific simulator
./utility/build_and_test.sh --simulator --verbose

# Debug with UI tests enabled
./utility/build_and_test.sh --verbose --enableUITests
```

## Error Handling

### Common Issues & Solutions

**1. Simulator Not Found**
```bash
# Script automatically finds alternative simulators
# Or manually specify: xcrun simctl list devices available
```

**2. Build Failures**
- Check `build/xcodebuild.log` for detailed error messages
- Verify Xcode command line tools: `xcode-select --install`
- Clean build: `./utility/build_and_test.sh --clean`

**3. Test Failures**
- Check `build/test.log` for specific test failures
- Review test implementation in `SpeechDictationTests/`
- Verify simulator compatibility

**4. UI Test Failures**
- Check `build/ui_test.log` for UI test failures (when enabled)
- UI tests are disabled by default for faster iteration
- Enable with `--enableUITests` flag when needed

**5. Permission Issues**
```bash
# Make scripts executable
chmod +x utility/*.sh
```

## Performance Optimization

### For Faster Iteration
1. **Use `quick_iterate.sh`** for development cycles
2. **UI tests are disabled by default** for speed
3. **Use simulator** instead of device for speed
4. **Avoid `--clean`

### Performance Optimizations

**Simulator Caching**: The script automatically caches the last used simulator to avoid re-selection overhead on subsequent runs. This can save 5-10 seconds per build.

**Optimized Boot Process**: Improved simulator boot detection reduces boot time from 45 seconds to typically 15-20 seconds.

**Build Optimization**: Uses `-quiet` and `-hideShellScriptEnvironment` flags to reduce build output noise and improve performance.

### Build Artifacts

All build artifacts are stored in the `build/` directory:
- `build/derived_data/` - Xcode derived data (preserved for incremental builds)
- `build/reports/` - Timestamped build and test reports
- `build/xcodebuild.log` - Latest build log
- `build/test.log` - Latest test log
- `build/.simulator_cache` - Cached simulator information for performance

### Cache Management

The simulator cache improves performance but can be managed:
```bash
# Clear cache and force re-selection
./utility/build_and_test.sh --cache-clear

# View cached simulator
cat build/.simulator_cache

# Manually remove cache
rm build/.simulator_cache
```