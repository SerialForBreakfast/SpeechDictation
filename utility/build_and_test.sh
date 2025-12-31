#!/bin/bash

# SpeechDictation iOS - Build and Test Automation Script
# Provides comprehensive build validation, test execution, and detailed reporting
# 
# Test Speed Optimizations (per ADR-TestSpeedImprovements.txt):
# - Uses build-for-testing + test-without-building pattern to avoid redundant rebuilds
# - Disables parallel testing (-parallel-testing-enabled NO) to prevent simulator clones
# - Pre-boots simulator to reduce launch latency
# - Includes timing diagnostics for performance analysis
# 
# Usage: ./utility/build_and_test.sh [--verbose] [--clean] [--device] [--simulator] [--disableUnitTests] [--enableUITests]
# Note: Unit tests run by default. Use --disableUnitTests to skip them.

set -e  # Exit on any error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_ROOT/build"
REPORTS_DIR="$BUILD_DIR/reports"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_FILE="$REPORTS_DIR/build_test_report_$TIMESTAMP.txt"
SIMULATOR_CACHE_FILE="$BUILD_DIR/.simulator_cache"

# Load simulator cache if it exists and is valid
load_simulator_cache() {
    if [[ -f "$SIMULATOR_CACHE_FILE" ]]; then
        source "$SIMULATOR_CACHE_FILE"
        # Verify cached simulator still exists and is available
        if [[ -n "$CACHED_SIMULATOR_UUID" ]]; then
            local sim_exists=$(xcrun simctl list devices | grep "$CACHED_SIMULATOR_UUID" || true)
            if [[ -n "$sim_exists" ]]; then
                SIMULATOR_NAME="$CACHED_SIMULATOR_NAME"
                SIMULATOR_OS="$CACHED_SIMULATOR_OS"
                SIMULATOR_UUID="$CACHED_SIMULATOR_UUID"
                log "INFO" "Using cached simulator: $SIMULATOR_NAME (iOS $SIMULATOR_OS) UUID: $SIMULATOR_UUID"
                return 0
            else
                log "WARN" "Cached simulator no longer available, will select new one"
                rm -f "$SIMULATOR_CACHE_FILE"
            fi
        fi
    fi
    return 1
}

# Save simulator cache for future runs
save_simulator_cache() {
    if [[ -n "$SIMULATOR_UUID" && -n "$SIMULATOR_NAME" && -n "$SIMULATOR_OS" ]]; then
        {
            echo "CACHED_SIMULATOR_NAME='$SIMULATOR_NAME'"
            echo "CACHED_SIMULATOR_OS='$SIMULATOR_OS'"
            echo "CACHED_SIMULATOR_UUID='$SIMULATOR_UUID'"
        } > "$SIMULATOR_CACHE_FILE"
        log "INFO" "Saved simulator cache for future runs"
    fi
}

# Parse command line arguments
VERBOSE=false
CLEAN_BUILD=false
TARGET_DEVICE=""
# Feature flags
ENABLE_UI_TESTS=false     # UI tests are opt-in via --enableUITests (slower, run less frequently)
ENABLE_UNIT_TESTS=true    # Unit tests run by default (fast, should run on every build)
CLEAR_CACHE=false         # Clear simulator cache and force re-selection
# Allow caller to override the simulator UUID
SIMULATOR_OVERRIDE_UUID=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose)
            VERBOSE=true
            shift
            ;;
        --clean)
            CLEAN_BUILD=true
            shift
            ;;
        --device)
            TARGET_DEVICE="device"
            shift
            ;;
        --simulator)
            TARGET_DEVICE="simulator"
            shift
            ;;
        --simulator-id|--simulatorID|--udid)
            # Expect a UUID immediately after the flag
            if [[ -n "$2" && "$2" != --* ]]; then
                SIMULATOR_OVERRIDE_UUID="$2"
                TARGET_DEVICE="simulator"
                shift 2
            else
                echo "Error: --simulator-id requires a UUID argument"
                exit 1
            fi
            ;;
        --enableUITests)
            ENABLE_UI_TESTS=true
            shift
            ;;
        --enableUnitTests|-enableUnitTests)
            ENABLE_UNIT_TESTS=true
            shift
            ;;
        --disableUnitTests|--noUnitTests)
            ENABLE_UNIT_TESTS=false
            shift
            ;;
        --cache-clear|--clear-cache)
            CLEAR_CACHE=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--verbose] [--clean] [--device] [--simulator] [--simulator-id <UUID>] [--disableUnitTests] [--enableUITests] [--cache-clear]"
            exit 1
            ;;
    esac
done

# Clear cache if requested
if [[ "$CLEAR_CACHE" == true ]]; then
    log "INFO" "Clearing simulator cache as requested"
    rm -f "$SIMULATOR_CACHE_FILE"
fi

# Create necessary directories
mkdir -p "$BUILD_DIR"
mkdir -p "$REPORTS_DIR"

# Initialize report
{
    echo "=== SpeechDictation iOS Build & Test Report ==="
    echo "Timestamp: $(date)"
    echo "Script Version: 2.0"
    echo "Project Root: $PROJECT_ROOT"
    echo "Report File: $REPORT_FILE"
    echo ""
} > "$REPORT_FILE"

# Log function with timestamp
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date +"%H:%M:%S")
    echo "[$timestamp] [$level] $message" | tee -a "$REPORT_FILE"
}

# Error handling function
handle_error() {
    local exit_code=$?
    local line_number=$1
    log "ERROR" "Build/test failed at line $line_number (exit code: $exit_code)"
    log "ERROR" "Last command: $BASH_COMMAND"
    
    # Capture system information for debugging
    {
        echo ""
        echo "=== System Information ==="
        echo "macOS Version: $(sw_vers -productVersion)"
        echo "Xcode Version: $(xcodebuild -version | head -n1)"
        echo "Available Simulators:"
        xcrun simctl list devices available | grep "iPhone\|iPad" | head -5
        echo ""
        echo "=== Recent Build Logs ==="
        tail -20 "$BUILD_DIR/xcodebuild.log" 2>/dev/null || echo "No build log available"
    } >> "$REPORT_FILE"
    
    exit $exit_code
}

# Set up error handling
trap 'handle_error $LINENO' ERR

# Universal simulator selection - works on any machine
select_simulator() {
    log "INFO" "Selecting best available simulator..." >&2
    
    # Always write awk output to a file and read from it
    xcrun simctl list devices available | awk '
        BEGIN { current_ios=""; best_ios=""; }
        /^-- iOS [0-9.]+ --/ {
            line = $0;
            sub(/^-- iOS /, "", line);
            sub(/ --$/, "", line);
            current_ios = line;
            next;
        }
        /\([A-F0-9-]+\)/ {
            line = $0;
            # Extract UUID from first parenthetical
            uuid = line;
            sub(/^[^(]*\(/, "", uuid); sub(/\).*/, "", uuid);
            # Extract device name
            device_name = line;
            sub(/^[[:space:]]*/, "", device_name);
            sub(/ \(.*/, "", device_name);
            # Only consider iPhone devices for best/any iPhone
            if (device_name ~ /iPhone/) {
                if (any_iphone == "") any_iphone = device_name "|" current_ios "|" uuid;
                if (best_iphone == "" || current_ios > best_ios) { best_iphone = device_name "|" current_ios "|" uuid; best_ios = current_ios; }
            }
            if (any_ios == "") any_ios = device_name "|" current_ios "|" uuid;
        }
        END {
            if (best_iphone != "") print best_iphone;
            else if (any_iphone != "") print any_iphone;
            else if (any_ios != "") print any_ios;
        }
    ' > /tmp/sim_result.txt
    local result
    result=$(cat /tmp/sim_result.txt)
    log "INFO" "sim_result.txt contents: '$result'" >&2
    echo "DEBUG: result='$result'" >&2
    if [ -n "$result" ]; then
        IFS='|' read -r SIMULATOR_NAME SIMULATOR_OS SIMULATOR_UUID <<< "$result"
        echo "DEBUG: SIMULATOR_NAME='$SIMULATOR_NAME' SIMULATOR_OS='$SIMULATOR_OS' SIMULATOR_UUID='$SIMULATOR_UUID'" >&2
        log "INFO" "Selected simulator: $SIMULATOR_NAME (iOS $SIMULATOR_OS) UUID: $SIMULATOR_UUID" >&2
        echo "$SIMULATOR_NAME|$SIMULATOR_OS|$SIMULATOR_UUID"
        return 0
    else
        log "ERROR" "No simulators available" >&2
        return 1
    fi
}

create_fresh_simulator() {
    log "INFO" "Attempting to create a fresh simulator from installed runtimes..." >&2
    
    local device_line runtime_line device_type runtime_id runtime_os
    
    device_line=$(xcrun simctl list devicetypes 2>/dev/null | grep -E "iPhone" | grep -vi "unavailable" | tail -1 || true)
    runtime_line=$(xcrun simctl list runtimes 2>/dev/null | grep -E "iOS [0-9.]+ \(" | grep -vi "unavailable" | tail -1 || true)
    
    if [[ -z "$device_line" || -z "$runtime_line" ]]; then
        log "ERROR" "Unable to locate compatible device types or runtimes. Ensure iOS simulator runtimes are installed via Xcode." >&2
        return 1
    fi
    
    device_type=$(echo "$device_line" | sed -E 's/.*\((com\.apple\.CoreSimulator\.SimDeviceType\.[^)]+)\).*/\1/')
    runtime_id=$(echo "$runtime_line" | sed -E 's/.*(com\.apple\.CoreSimulator\.SimRuntime\.[^)]+)\).*/\1/')
    runtime_os=$(echo "$runtime_line" | sed -E 's/.*iOS ([0-9.]+).*/\1/')
    
    if [[ -z "$device_type" || -z "$runtime_id" ]]; then
        log "ERROR" "Parsed simulator identifiers were empty. Device line: $device_line Runtime line: $runtime_line" >&2
        return 1
    fi
    
    local simulator_name="SpeechDictation Auto iOS $runtime_os"
    local new_uuid
    if new_uuid=$(xcrun simctl create "$simulator_name" "$device_type" "$runtime_id" 2>/dev/null); then
        new_uuid=$(echo "$new_uuid" | tr -d '[:space:]')
        log "INFO" "Created simulator: $simulator_name UUID: $new_uuid" >&2
        echo "$simulator_name|$runtime_os|$new_uuid"
        return 0
    else
        log "ERROR" "Failed to create simulator with type $device_type and runtime $runtime_id" >&2
        return 1
    fi
}

# Fast simulator status check
get_simulator_status() {
    local simulator_uuid="$1"
    xcrun simctl list devices | grep "$simulator_uuid" | grep -o "Booted\|Shutdown\|Crashed" | head -1
}

# Optimized simulator boot with faster status checking
boot_simulator_fast() {
    local simulator_uuid="$1"
    local status=$(get_simulator_status "$simulator_uuid")
    
    if [[ "$status" == "Booted" ]]; then
        log "INFO" "Simulator already booted and ready"
        return 0
    fi
    
    log "INFO" "Booting simulator $simulator_uuid..."
    xcrun simctl boot "$simulator_uuid" > /dev/null 2>&1
    
    # Wait for boot with optimized checking
    local attempts=0
    while [[ $attempts -lt 30 ]]; do
        status=$(get_simulator_status "$simulator_uuid")
        if [[ "$status" == "Booted" ]]; then
            # Quick responsiveness test
            if xcrun simctl list devices "$simulator_uuid" >/dev/null 2>&1; then
                log "INFO" "Simulator is ready"
                return 0
            fi
        elif [[ "$status" == "Crashed" ]]; then
            log "WARN" "Simulator crashed, attempting recovery..."
            xcrun simctl shutdown "$simulator_uuid" > /dev/null 2>&1
            sleep 2
            xcrun simctl boot "$simulator_uuid" > /dev/null 2>&1
            attempts=0  # Reset attempts after recovery
        fi
        sleep 1
        ((attempts++))
    done
    
    log "WARN" "Simulator boot timeout - may need manual intervention"
    return 1
}

# Simulator management functions
manage_simulator() {
    local action="$1"
    local simulator_uuid="$2"
    
    case "$action" in
        "boot")
            if [[ -n "$simulator_uuid" ]]; then
                boot_simulator_fast "$simulator_uuid"
            else
                log "WARN" "No simulator UUID provided for boot"
                return 1
            fi
            ;;
        "shutdown")
            if [[ -n "$simulator_uuid" ]]; then
                log "INFO" "Shutting down simulator..."
                xcrun simctl shutdown "$simulator_uuid" > /dev/null 2>&1
            fi
            ;;
        "cleanup")
            # Only cleanup if explicitly requested
            if [[ "$CLEAN_BUILD" == true && -n "$simulator_uuid" ]]; then
                log "INFO" "Cleaning simulator state..."
                xcrun simctl erase "$simulator_uuid" > /dev/null 2>&1
            fi
            ;;
    esac
}

# Function to check prerequisites
check_prerequisites() {
    log "INFO" "Checking prerequisites..."
    
    # Check if we're in the right directory
    if [[ ! -f "$PROJECT_ROOT/SpeechDictation.xcodeproj/project.pbxproj" ]]; then
        log "ERROR" "SpeechDictation.xcodeproj not found in $PROJECT_ROOT"
        exit 1
    fi
    
    # Check Xcode installation
    if ! command -v xcodebuild &> /dev/null; then
        log "ERROR" "Xcode command line tools not found"
        exit 1
    fi
    
    # Select simulator if needed
    if [[ "$TARGET_DEVICE" != "device" ]]; then

        if [[ -n "$SIMULATOR_OVERRIDE_UUID" ]]; then
            # Clear cache when user specifies a specific simulator
            rm -f "$SIMULATOR_CACHE_FILE"
            # Validate that the provided UUID exists on this machine
            local sim_line
            sim_line=$(xcrun simctl list devices | grep "$SIMULATOR_OVERRIDE_UUID" || true)
            if [[ -z "$sim_line" ]]; then
                log "ERROR" "Specified simulator UUID $SIMULATOR_OVERRIDE_UUID not found on this host."
                exit 1
            fi

            # Extract name and OS version from the device listing
            # Example line: "    iPhone SE (3rd generation) (1A331965-FAA7-...) (Shutdown, iOS 17.5)"
            SIMULATOR_UUID="$SIMULATOR_OVERRIDE_UUID"
            SIMULATOR_NAME=$(echo "$sim_line" | sed -E 's/^[[:space:]]*([^()]*) \(.*/\1/')
            SIMULATOR_OS=$(echo "$sim_line" | sed -E 's/.*iOS ([0-9.]+).*/\1/')
            log "INFO" "Using user-specified simulator: $SIMULATOR_NAME (iOS $SIMULATOR_OS) UUID: $SIMULATOR_UUID"

            # Pre-boot simulator for faster test execution
            boot_simulator_fast "$SIMULATOR_UUID"
            # Save the user-specified simulator to cache
            save_simulator_cache

        else
            # Try to load cached simulator first
            if load_simulator_cache; then
                # Pre-boot cached simulator
                boot_simulator_fast "$SIMULATOR_UUID"
            else
            local simulator_info
            simulator_info=$(select_simulator)
            if [[ $? -ne 0 || -z "$simulator_info" ]]; then
                log "WARN" "Automatic simulator selection failed, attempting to create a new simulator..."
                simulator_info=$(create_fresh_simulator)
            fi
            if [[ -n "$simulator_info" ]]; then
                IFS='|' read -r SIMULATOR_NAME SIMULATOR_OS SIMULATOR_UUID <<< "$simulator_info"
                export SIMULATOR_NAME
                export SIMULATOR_OS
                export SIMULATOR_UUID
                log "INFO" "Selected simulator: $SIMULATOR_NAME (iOS $SIMULATOR_OS) UUID: $SIMULATOR_UUID"
                # Pre-boot simulator for faster test execution
                if [[ -n "$SIMULATOR_UUID" ]]; then
                    log "INFO" "Pre-booting simulator for faster test execution..."
                    boot_simulator_fast "$SIMULATOR_UUID"
                    # Save newly selected simulator to cache
                    save_simulator_cache
                else
                    log "ERROR" "No simulator UUID found after selection or creation."
                    exit 1
                fi
            else
                log "ERROR" "Failed to select or create a simulator. Install an iOS simulator runtime via Xcode > Settings > Platforms."
                exit 1
            fi
            fi
        fi
    fi
    
    log "INFO" "Prerequisites check completed successfully"
}

# Function to clean build artifacts
clean_build() {
    if [[ "$CLEAN_BUILD" == true ]]; then
        log "INFO" "Cleaning build artifacts..."
        rm -rf "$BUILD_DIR/derived_data"
        xcodebuild clean -project "$PROJECT_ROOT/SpeechDictation.xcodeproj" -scheme SpeechDictation >> "$REPORT_FILE" 2>&1
        
        # Only erase simulator if explicitly cleaning
        if [[ "$TARGET_DEVICE" != "device" ]]; then
            log "INFO" "Cleaning simulator state..."
            manage_simulator "cleanup" "$SIMULATOR_UUID"
        fi
        
        log "INFO" "Clean completed"
    else
        # Check if we can use incremental builds
        if [[ -d "$BUILD_DIR/derived_data" ]]; then
            log "INFO" "Using incremental build (derived data exists)"
        else
            log "INFO" "Performing full build (no derived data)"
        fi
        
        # Note: We're NOT erasing simulator state for faster subsequent runs
        log "INFO" "Preserving simulator state for faster test execution"
    fi
}

# Function to build the project for testing (Phase 2: build-for-testing pattern)
build_project() {
    log "INFO" "Building SpeechDictation project for testing..."
    
    local build_log="$BUILD_DIR/xcodebuild.log"
    local build_args=(
        -project "$PROJECT_ROOT/SpeechDictation.xcodeproj"
        -scheme SpeechDictation
        -configuration Debug
        -derivedDataPath "$BUILD_DIR/derived_data"
        -quiet
        -hideShellScriptEnvironment
    )
    
    # Add simulator destination for build. Prefer UUID if available to avoid name/OS parsing issues.
    if [[ "$TARGET_DEVICE" != "device" ]]; then
        if [[ -n "$SIMULATOR_UUID" ]]; then
            build_args+=(-destination "platform=iOS Simulator,id=$SIMULATOR_UUID")
        else
            build_args+=(-destination "platform=iOS Simulator,name=$SIMULATOR_NAME,OS=$SIMULATOR_OS")
        fi
    fi
    
    if [[ "$VERBOSE" == true ]]; then
        build_args+=(-verbose)
    fi
    
    # Clear previous build log
    > "$build_log"
    
    # Build for testing (enables test-without-building in subsequent runs)
    update_currently_running "[Build] Compiling for testing..."
    local build_exit_code=0
    xcodebuild build-for-testing "${build_args[@]}" > "$build_log" 2>&1 || build_exit_code=$?
    
    if [[ $build_exit_code -eq 0 ]]; then
        log "SUCCESS" "Project built for testing successfully"
        # Ensure build log has success marker for summary generation
        if ! grep -qE "(BUILD.*SUCCEEDED|BUILD SUCCEEDED)" "$build_log"; then
            echo "** BUILD SUCCEEDED **" >> "$build_log"
        fi
        return 0
    else
        log "ERROR" "Build failed. Check $build_log for details"
        return 1
    fi
}

# Add a function to update the currently running status in-place
update_currently_running() {
    local status="$1"
    # Console: overwrite the last line
    echo -ne "\rCurrentlyRunning: $status" 1>&2
    # Report: overwrite the last line
    if [[ -f "$REPORT_FILE" ]]; then
        # Remove the last CurrentlyRunning line if present
        sed -i '' '/^CurrentlyRunning:/d' "$REPORT_FILE"
        echo "CurrentlyRunning: $status" >> "$REPORT_FILE"
    fi
}

# At the end of each phase, clear the status
clear_currently_running() {
    echo -ne "\r" 1>&2
    if [[ -f "$REPORT_FILE" ]]; then
        sed -i '' '/^CurrentlyRunning:/d' "$REPORT_FILE"
    fi
}

# Function to pre-boot simulator (reduces launch latency)
preboot_simulator() {
    if [[ -n "$SIMULATOR_UUID" ]]; then
        log "INFO" "Pre-booting simulator $SIMULATOR_UUID..."
        local start_boot=$(date +%s)
        xcrun simctl boot "$SIMULATOR_UUID" 2>/dev/null || true
        xcrun simctl bootstatus "$SIMULATOR_UUID" -b 2>/dev/null || true
        local end_boot=$(date +%s)
        local boot_duration=$((end_boot - start_boot))
        log "INFO" "Simulator boot+ready: ${boot_duration}s"
    fi
}

# Function to run unit tests (Phase 1 & 2: parallel testing disabled, test-without-building)
run_unit_tests() {
    log "INFO" "Running unit tests..."
    update_currently_running "[Testing] Running unit tests"
    
    # Phase 3: Pre-boot simulator to reduce launch latency
    preboot_simulator
    
    local test_log="$BUILD_DIR/test.log"
    local start_test=$(date +%s)
    
    # Use the already selected simulator UUID
    local destination_arg
    if [[ -n "$SIMULATOR_UUID" ]]; then
        destination_arg="platform=iOS Simulator,id=$SIMULATOR_UUID"
        log "INFO" "Using simulator UUID: $SIMULATOR_UUID"
    else
        destination_arg="platform=iOS Simulator,name=$SIMULATOR_NAME,OS=$SIMULATOR_OS"
        log "WARN" "Using simulator name/OS fallback"
    fi
    
    local test_args=(
        -project "$PROJECT_ROOT/SpeechDictation.xcodeproj"
        -scheme SpeechDictation
        -destination "$destination_arg"
        -derivedDataPath "$BUILD_DIR/derived_data"
        -only-testing:SpeechDictationTests
        -quiet
        -hideShellScriptEnvironment
        -parallel-testing-enabled NO
        -maximum-parallel-testing-workers 1
    )
    
    if [[ "$VERBOSE" == true ]]; then
        test_args+=(-verbose)
    fi
    
    # Clear previous test log
    > "$test_log"
    
    # Phase 2: Use test-without-building (assumes build-for-testing was run)
    xcodebuild test-without-building "${test_args[@]}" > "$test_log" 2>&1 &
    local test_pid=$!
    
    # Improved progress monitoring with better regex patterns
    local last_test=""
    while kill -0 $test_pid 2>/dev/null; do
        if [[ -f "$test_log" ]]; then
            # Look for test case patterns in multiple formats
            local current_test=$(grep -Eo "(Test Case '-\[.*\]'.*started|Test Case '.*'.*started|Test case '.*'.*started)" "$test_log" | tail -1 | sed -E "s/.*\[(.*)\] (.*)/\2/" | sed -E "s/Test Case '([^']*)'.*/\1/" | awk '{print $1}')
            
            # If no test case found, look for test suite
            if [[ -z "$current_test" ]]; then
                current_test=$(grep -Eo "Test suite '.*' started" "$test_log" | tail -1 | sed -E "s/Test suite '([^']*)'.*/\1/")
            fi
            
            # If still no test found, look for any test activity
            if [[ -z "$current_test" ]]; then
                current_test=$(grep -Eo "Testing.*started" "$test_log" | tail -1 | sed -E "s/Testing (.*) started.*/\1/")
            fi
            
            if [[ -n "$current_test" && "$current_test" != "$last_test" ]]; then
                update_currently_running "[Testing] $current_test"
                last_test="$current_test"
            fi
        fi
        sleep 1  # Reduced from 2 seconds to 1 second for more responsive updates
    done
    # Capture xcodebuild exit code (don't let `set -e` abort before we can report)
    set +e
    wait $test_pid
    local test_exit_code=$?
    set -e
    clear_currently_running
    
    local end_test=$(date +%s)
    local test_duration=$((end_test - start_test))
    
    # Newer xcodebuild output may omit the legacy "** TEST SUCCEEDED **" sentinel line.
    # Prefer the actual process exit code, and fall back to log parsing if needed.
    if [[ "$test_exit_code" -eq 0 ]]; then
        log "SUCCESS" "Unit tests passed (duration: ${test_duration}s)"
        local test_summary=$(grep -E "(Test Suite|Test Case|PASS|FAIL)" "$test_log" | tail -10)
        {
            echo ""
            echo "=== Test Results Summary ==="
            echo "Test execution duration: ${test_duration}s"
            echo "$test_summary"
        } >> "$REPORT_FILE"
        return 0
    else
        log "ERROR" "Unit tests failed (duration: ${test_duration}s). Check $test_log for details"
        local test_failures=$(grep -A 5 -B 5 "FAIL\|error:" "$test_log" | tail -20)
        {
            echo ""
            echo "=== Test Failures ==="
            echo "Test execution duration: ${test_duration}s"
            echo "$test_failures"
        } >> "$REPORT_FILE"
        return 1
    fi
}

# Function to run UI tests (optional)
run_ui_tests() {
    if [[ "$ENABLE_UI_TESTS" == false ]]; then
        log "INFO" "UI tests are disabled. Skipping UI tests."
        update_currently_running "[Testing] UI tests are disabled"
        sleep 1
        clear_currently_running
        return 0
    fi
    log "INFO" "Running UI tests..."
    update_currently_running "[Testing] Running UI tests"
    
    local ui_test_log="$BUILD_DIR/ui_test.log"
    
    # Use the already selected simulator UUID
    local destination_arg
    if [[ -n "$SIMULATOR_UUID" ]]; then
        destination_arg="platform=iOS Simulator,id=$SIMULATOR_UUID"
    else
        destination_arg="platform=iOS Simulator,name=$SIMULATOR_NAME,OS=$SIMULATOR_OS"
    fi
    
    local ui_test_args=(
        -project "$PROJECT_ROOT/SpeechDictation.xcodeproj"
        -scheme SpeechDictation
        -destination "$destination_arg"
        -derivedDataPath "$BUILD_DIR/derived_data"
        -only-testing:SpeechDictationUITests
        -quiet
        -hideShellScriptEnvironment
        -parallel-testing-enabled NO
        -maximum-parallel-testing-workers 1
    )
    
    if [[ "$VERBOSE" == true ]]; then
        ui_test_args+=(-verbose)
    fi
    
    # Clear previous UI test log
    > "$ui_test_log"
    
    xcodebuild test "${ui_test_args[@]}" > "$ui_test_log" 2>&1 &
    local ui_test_pid=$!
    
    # Improved progress monitoring for UI tests
    local last_ui_test=""
    while kill -0 $ui_test_pid 2>/dev/null; do
        if [[ -f "$ui_test_log" ]]; then
            # Look for test case patterns in multiple formats
            local current_ui_test=$(grep -Eo "(Test Case '-\[.*\]'.*started|Test Case '.*'.*started|Test case '.*'.*started)" "$ui_test_log" | tail -1 | sed -E "s/.*\[(.*)\] (.*)/\2/" | sed -E "s/Test Case '([^']*)'.*/\1/" | awk '{print $1}')
            
            # If no test case found, look for test suite
            if [[ -z "$current_ui_test" ]]; then
                current_ui_test=$(grep -Eo "Test suite '.*' started" "$ui_test_log" | tail -1 | sed -E "s/Test suite '([^']*)'.*/\1/")
            fi
            
            # If still no test found, look for any test activity
            if [[ -z "$current_ui_test" ]]; then
                current_ui_test=$(grep -Eo "Testing.*started" "$ui_test_log" | tail -1 | sed -E "s/Testing (.*) started.*/\1/")
            fi
            
            if [[ -n "$current_ui_test" && "$current_ui_test" != "$last_ui_test" ]]; then
                update_currently_running "[Testing] $current_ui_test"
                last_ui_test="$current_ui_test"
            fi
        fi
        sleep 1  # Reduced from 2 seconds to 1 second for more responsive updates
    done
    wait $ui_test_pid
    clear_currently_running
    
    if grep -q "\*\* TEST SUCCEEDED \*\*" "$ui_test_log"; then
        log "SUCCESS" "UI tests passed"
        return 0
    else
        log "WARN" "UI tests failed (non-critical). Check $ui_test_log for details"
        return 0
    fi
}

# Function to generate performance metrics
generate_metrics() {
    log "INFO" "Generating build metrics..."
    
    # Calculate build time
    local build_start_time=$(grep "BUILD SUCCEEDED" "$BUILD_DIR/xcodebuild.log" | head -1 | grep -o "[0-9]\+\.[0-9]\+ seconds" || echo "unknown")
    
    # Count test results
    local total_tests=$(grep "Test Case.*passed" "$BUILD_DIR/test.log" | wc -l)
    local failed_tests=$(grep "Test Case.*failed" "$BUILD_DIR/test.log" | wc -l)
    
    # Calculate project size
    local project_size=$(du -sh "$PROJECT_ROOT" | cut -f1)
    
    {
        echo ""
        echo "=== Performance Metrics ==="
        echo "Build Time: $build_start_time"
        echo "Total Tests: $total_tests"
        echo "Failed Tests: $failed_tests"
        echo "Project Size: $project_size"
        echo "Available Disk Space: $(df -h . | tail -1 | awk '{print $4}')"
    } >> "$REPORT_FILE"
}

# Function to generate summary
generate_summary() {
    local exit_code=$1
    
    # Check actual log files to determine status
    local build_status="FAILED"
    local unit_test_status="NOT_RUN"
    local ui_test_status="NOT_RUN"
    
    # Check build status (build-for-testing may output "BUILD SUCCEEDED" or we added it manually)
    if [[ -f "$BUILD_DIR/xcodebuild.log" ]]; then
        if grep -qE "(BUILD.*SUCCEEDED|BUILD SUCCEEDED)" "$BUILD_DIR/xcodebuild.log"; then
            build_status="SUCCESS"
        elif [[ -s "$BUILD_DIR/xcodebuild.log" ]]; then
            # If log exists and has content but no success message, check for failure indicators
            if grep -qiE "(BUILD FAILED|error:|failed)" "$BUILD_DIR/xcodebuild.log"; then
                build_status="FAILED"
            else
                # No failure indicators - assume success (tests wouldn't run if build failed)
                build_status="SUCCESS"
            fi
        fi
    fi
    
    # Determine unit test status based on flag and logs
    if [[ "$ENABLE_UNIT_TESTS" == false ]]; then
        unit_test_status="DISABLED"
    else
        if [[ -f "$BUILD_DIR/test.log" ]]; then
            # Tests ran - check for success or failure
            if grep -qE "(\*\* TEST SUCCEEDED \*\*|Test Suite.*passed)" "$BUILD_DIR/test.log"; then
                unit_test_status="SUCCESS"
            elif grep -qE "(TEST EXECUTE FAILED|Failing tests:|Test Case.*failed)" "$BUILD_DIR/test.log"; then
                unit_test_status="FAILED"
            else
                # Test log exists but unclear status - check if tests actually ran
                if grep -qE "(Testing started|Test Suite)" "$BUILD_DIR/test.log"; then
                    unit_test_status="FAILED"  # Tests ran but no success marker
                else
                    unit_test_status="NOT_RUN"
                fi
            fi
        elif [[ "$build_status" == "FAILED" ]]; then
            unit_test_status="SKIPPED"
        else
            unit_test_status="NOT_RUN"
        fi
    fi
    
    # Check UI test status (only if build succeeded and enabled)
    if [[ "$build_status" == "SUCCESS" && "$ENABLE_UI_TESTS" == true && -f "$BUILD_DIR/ui_test.log" ]]; then
        if grep -q "\*\* TEST SUCCEEDED \*\*" "$BUILD_DIR/ui_test.log"; then
            ui_test_status="SUCCESS"
        else
            ui_test_status="FAILED"
        fi
    elif [[ "$build_status" == "FAILED" ]]; then
        ui_test_status="SKIPPED"
    elif [[ "$ENABLE_UI_TESTS" == false ]]; then
        ui_test_status="DISABLED"
    fi
    
    {
        echo ""
        echo "=== Build & Test Summary ==="
        echo "Overall Status: $([[ $exit_code -eq 0 ]] && echo "SUCCESS" || echo "FAILED")"
        echo "Build: $build_status"
        echo "Unit Tests: $unit_test_status"
        echo "UI Tests: $ui_test_status"
        echo ""
        echo "Report Location: $REPORT_FILE"
        echo "Build Log: $BUILD_DIR/xcodebuild.log"
        echo "Test Log: $BUILD_DIR/test.log"
        echo "UI Test Log: $BUILD_DIR/ui_test.log"
    } >> "$REPORT_FILE"
    
    # Display summary to console
    echo ""
    echo "=== Build & Test Complete ==="
    echo "Status: $([[ $exit_code -eq 0 ]] && echo "SUCCESS" || echo "FAILED")"
    echo "Report: $REPORT_FILE"
    echo ""
}

# Main execution
main() {
    local start_all=$(date +%s)
    update_currently_running "[Prerequisites] Checking prerequisites"
    log "INFO" "Starting SpeechDictation build and test automation"
    log "INFO" "Arguments: VERBOSE=$VERBOSE, CLEAN=$CLEAN_BUILD, TARGET=$TARGET_DEVICE, ENABLE_UNIT_TESTS=$ENABLE_UNIT_TESTS, ENABLE_UI_TESTS=$ENABLE_UI_TESTS, CLEAR_CACHE=$CLEAR_CACHE"
    
    local overall_exit_code=0
    
    check_prerequisites || { overall_exit_code=1; return $overall_exit_code; }
    update_currently_running "[Build] Building SpeechDictation project"
    clean_build
    build_project || { 
        overall_exit_code=1
        clear_currently_running
        update_currently_running "[Summary] Generating build & test summary"
        generate_summary $overall_exit_code
        clear_currently_running
        update_currently_running "[Complete] Build failed - skipping tests"
        sleep 1
        clear_currently_running
        return $overall_exit_code
    }
    clear_currently_running

    if [[ "$ENABLE_UNIT_TESTS" == true ]]; then
        update_currently_running "[Testing] Running unit tests"
        run_unit_tests || { overall_exit_code=1; }
    else
        update_currently_running "[Testing] Unit tests are disabled"
    fi
    if [[ "$ENABLE_UI_TESTS" == true ]]; then
        update_currently_running "[Testing] Running UI tests"
    else
        update_currently_running "[Testing] UI tests are disabled"
    fi
    run_ui_tests
    clear_currently_running
    update_currently_running "[Metrics] Generating build metrics"
    generate_metrics
    clear_currently_running
    update_currently_running "[Summary] Generating build & test summary"
    generate_summary $overall_exit_code
    clear_currently_running
    
    local end_all=$(date +%s)
    local total_duration=$((end_all - start_all))
    log "INFO" "Total execution time: ${total_duration}s"
    {
        echo ""
        echo "=== Timing Summary ==="
        echo "Total execution time: ${total_duration}s"
    } >> "$REPORT_FILE"
    
    update_currently_running "[Complete] Build & test process finished (${total_duration}s)"
    sleep 1
    clear_currently_running
    return $overall_exit_code
}

# Execute main function
main "$@" 