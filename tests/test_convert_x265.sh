#!/bin/bash

# Test script for convert_x265

set -euo pipefail

SCRIPT_PATH="/usr/local/bin/convert_x265"
TEST_DIR="$(mktemp -d /tmp/test_convert_x265_XXXXXX)"
PREFERENCES_FILE="$TEST_DIR/preferences.conf"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

pass() { echo -e "${GREEN}[PASS]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; }

# Test 1: Check --version output
test_version() {
    echo "Running test: --version"
    if "$SCRIPT_PATH" --version &>/dev/null; then
        pass "--version displays version correctly."
    else
        fail "--version failed."
    fi
}

# Test 2: Check missing preferences.conf error
test_missing_preferences() {
    echo "Running test: Missing preferences.conf"
    rm -f "$PREFERENCES_FILE"
    if "$SCRIPT_PATH" --dir "$TEST_DIR" 2>&1 | grep -q "preferences.conf not found"; then
        pass "Missing preferences.conf error handled correctly."
    else
        fail "Missing preferences.conf error not handled."
    fi
}

# Trap to clean up on exit
cleanup() {
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

# Run tests
test_version
test_missing_preferences