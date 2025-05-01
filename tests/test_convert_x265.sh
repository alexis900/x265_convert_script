#!/bin/bash

# Test script for convert_x265

SCRIPT_PATH="/usr/local/bin/convert_x265"
TEST_DIR="/tmp/test_convert_x265"
PREFERENCES_FILE="$TEST_DIR/preferences.conf"

# Create a temporary test directory
mkdir -p "$TEST_DIR"

# Test 1: Check --version output
function test_version() {
    echo "Running test: --version"
    $SCRIPT_PATH --version
    if [[ $? -eq 0 ]]; then
        echo "[PASS] --version displays version correctly."
    else
        echo "[FAIL] --version failed."
    fi
}

# Test 2: Check missing preferences.conf error
function test_missing_preferences() {
    echo "Running test: Missing preferences.conf"
    rm -f "$PREFERENCES_FILE"  # Ensure preferences.conf is missing
    $SCRIPT_PATH --dir "$TEST_DIR" 2>&1 | grep -q "preferences.conf not found"
    if [[ $? -eq 0 ]]; then
        echo "[PASS] Missing preferences.conf error handled correctly."
    else
        echo "[FAIL] Missing preferences.conf error not handled."
    fi
}

# Run tests
test_version
test_missing_preferences

# Clean up
rm -rf "$TEST_DIR"

exit 0