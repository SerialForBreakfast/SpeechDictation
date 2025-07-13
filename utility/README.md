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
- ⚡ **Fast Execution** - Minimal output, quick feedback
- ⚡ **Simulator Focused** - Uses iPhone 15 simulator by default
- ⚡ **Development Optimized** - Skips UI tests for speed (can be enabled)
- ⚡ **Quick Summary** - Essential status information only

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
4. **Avoid `--clean`** unless necessary
5. **Only enable UI tests** when specifically needed

### For Production Validation
1. **Use `build_and_test.sh`** for comprehensive testing
2. **Include `--device`** for real device validation
3. **Use `--verbose`** for detailed logging
4. **Always `--clean`** for release builds
5. **Consider `--enableUITests`** for full validation

## Configuration

### Customizing Simulator
Edit `build_and_test.sh`:
```bash
SIMULATOR_NAME="iPhone 15"  # Change device
SIMULATOR_OS="17.5"         # Change iOS version
```

### Customizing Build Settings
Edit build arguments in `build_project()`:
```bash
-configuration Debug          # Change to Release
-derivedDataPath "$BUILD_DIR/derived_data"  # Custom path
```

### UI Test Configuration
- **Default**: UI tests are disabled for faster iteration
- **Enable**: Use `--enableUITests` flag when UI testing is needed
- **CI/CD**: Consider enabling UI tests for comprehensive validation

## Monitoring & Analytics

### Key Metrics Tracked
- **Build Time** - Performance monitoring
- **Test Count** - Coverage tracking (unit tests only by default)
- **UI Test Count** - UI test coverage (when enabled)
- **Failure Rate** - Quality metrics
- **Project Size** - Growth monitoring
- **Disk Space** - Resource management

### Historical Analysis
Reports are timestamped for trend analysis:
```bash
# List recent reports
ls -la build/reports/

# Analyze trends
grep "Build Time" build/reports/*.txt

# Check UI test trends (when enabled)
grep "UI tests" build/reports/*.txt
```

---

## Quick Start

1. **First Run:**
   ```bash
   ./utility/quick_iterate.sh
   ```

2. **After Code Changes:**
   ```bash
   ./utility/quick_iterate.sh
   ```

3. **Before Commits:**
   ```bash
   ./utility/build_and_test.sh --clean
   ```

4. **For Production:**
   ```bash
   ./utility/build_and_test.sh --device --verbose
   ```

5. **With UI Tests:**
   ```bash
   ./utility/build_and_test.sh --clean --enableUITests
   ```

---

*Last Updated: December 19, 2024*
*Script Version: 1.1*