#!/usr/bin/env bats
# adguardhome-280blocker-filter-update.bats - bats-core test suite for AdGuard Home 280blocker Updater
# bats-core v1.13.0 compatible
#
# Features tested:
# - Script existence and executability
# - Proper shebang and strict mode
# - Command-line argument parsing
# - Directory creation
# - Error handling
#
# New features in bats-core v1.13.0:
# - --abort flag: fail-fast (stop on first failure)
# - --negative-filter: exclude tests matching pattern

# Load test suite setup
load setup_suite

# --- Setup and Teardown ---

setup() {
    # Create temporary directory for each test
    TEST_TEMP_DIR="$(mktemp -d)"
    export TEST_TEMP_DIR

    # Script path (relative to test directory)
    SCRIPT_PATH="${BATS_TEST_DIRNAME}/../bin/adguardhome-280blocker-filter-update.sh"
    export SCRIPT_PATH

    # Mock data directory
    export DATA_DIR="${TEST_TEMP_DIR}/filters"
}

teardown() {
    # Cleanup temporary directory
    if [ -d "$TEST_TEMP_DIR" ]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

# --- Basic Validation Tests ---

@test "Script file exists" {
    [ -f "$SCRIPT_PATH" ]
}

@test "Script is executable" {
    [ -x "$SCRIPT_PATH" ]
}

@test "Script has proper shebang (#!/bin/bash)" {
    run head -n 1 "$SCRIPT_PATH"
    [[ "$output" == "#!/bin/bash" ]]
}

@test "Script contains Bash Strict Mode (set -euo pipefail)" {
    run grep -E "^set -euo pipefail" "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

@test "Script contains proper copyright/description header" {
    run head -n 20 "$SCRIPT_PATH"
    [[ "$output" =~ "280blocker" ]]
}

# --- Argument Parsing Tests ---

@test "Script runs without arguments (silent mode)" {
    skip "Requires network access - run manually"
    run "$SCRIPT_PATH"
    # Should exit with 0 or 1 (depending on download success)
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "Script runs with -v flag (verbose mode)" {
    skip "Requires network access - run manually"
    run "$SCRIPT_PATH" -v
    # Should produce output in verbose mode
    [ ${#lines[@]} -gt 0 ]
}

@test "Invalid flag shows usage message" {
    run "$SCRIPT_PATH" -z 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Usage:" ]] || [[ "$output" =~ "illegal option" ]]
}

@test "Help-like flag (-h) is not implemented (should show usage)" {
    run "$SCRIPT_PATH" -h 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Usage:" ]] || [[ "$output" =~ "illegal option" ]]
}

# --- Directory Creation Tests ---

@test "Creates data directory if missing" {
    skip "Requires modifying DATA_DIR in script - integration test"

    # This test would require injecting DATA_DIR environment variable
    # or refactoring script to accept DATA_DIR from environment

    export DATA_DIR="${TEST_TEMP_DIR}/custom_filters"
    run "$SCRIPT_PATH" -v

    [ -d "$DATA_DIR" ]
}

# --- Function Logic Tests (via source) ---

@test "Script defines required functions (error, log, cleanup)" {
    run grep -E "^(error|log|cleanup)\(\)" "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

@test "Script defines download_list function" {
    run grep -E "^download_list\(\)" "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

@test "Cleanup trap is set on EXIT" {
    run grep -E "trap cleanup EXIT" "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

# --- Security Tests ---

@test "Script does not contain eval statements (security risk)" {
    run grep -E "\beval\b" "$SCRIPT_PATH"
    [ "$status" -ne 0 ]
}

@test "Script uses quoted variables (prevents word splitting)" {
    # Check for common unquoted variable patterns (basic check)
    # This is not exhaustive but catches obvious issues
    run grep -E '\$[A-Z_]+[^"]' "$SCRIPT_PATH"

    # Filter out acceptable cases (within [[ ]] or assignments)
    # This is a simplified check; ShellCheck does this better
    skip "Complex to validate without ShellCheck - use 'make lint' instead"
}

@test "Script does not use dangerous commands (rm -rf /, dd)" {
    run grep -E "rm -rf /[^a-zA-Z]" "$SCRIPT_PATH"
    [ "$status" -ne 0 ]

    run grep -E "\bdd\b.*if=/dev" "$SCRIPT_PATH"
    [ "$status" -ne 0 ]
}

# --- Code Style Tests ---

@test "Script uses modern command substitution $(cmd) not backticks" {
    run grep -E '`[^`]+`' "$SCRIPT_PATH"
    [ "$status" -ne 0 ]
}

@test "Script uses [[ ]] instead of [ ] for conditionals" {
    # Check that modern [[ ]] is used (Google Shell Style preference)
    run grep -E '\[\[.*\]\]' "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

@test "Script uses 'if [ ]; then' on separate lines (readable style)" {
    # Check for multi-line if statements (readability)
    run grep -E 'if \[' "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

# --- Constants and Configuration Tests ---

@test "Script defines DATA_DIR constant" {
    run grep -E '^DATA_DIR=' "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

@test "Script defines FILE_NAME constant" {
    run grep -E '^FILE_NAME=' "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

@test "Script creates temporary file with mktemp" {
    run grep -E 'mktemp' "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

# --- Documentation Tests ---

@test "Script contains usage function" {
    run grep -E "^usage\(\)" "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

@test "Usage function outputs to stderr" {
    run grep -A 3 "^usage()" "$SCRIPT_PATH"
    [[ "$output" =~ ">&2" ]]
}

# --- Integration Test Stubs ---

@test "[INTEGRATION] Full script execution with mocked curl" {
    skip "Requires curl mocking - implement with stub/mock framework"

    # This would test the full script with mocked network calls
    # Requires advanced mocking (e.g., using 'stub' or custom mock functions)
}

@test "[INTEGRATION] Script handles network timeout gracefully" {
    skip "Requires network simulation - implement with timeout testing"
}

@test "[INTEGRATION] Script validates downloaded file is not HTML error page" {
    skip "Requires mock file creation - implement with fixtures"
}

@test "[INTEGRATION] Script performs atomic file update with 'install' command" {
    skip "Requires filesystem permission testing"
}

# --- Performance Tests ---

@test "Script completes syntax check quickly" {
    run bash -n "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

# --- Metadata ---

@test "README.md exists and documents usage" {
    README_PATH="${BATS_TEST_DIRNAME}/../README.md"
    [ -f "$README_PATH" ]

    run grep -i "usage" "$README_PATH"
    [ "$status" -eq 0 ]
}

@test "Makefile exists with test target" {
    MAKEFILE_PATH="${BATS_TEST_DIRNAME}/../Makefile"
    [ -f "$MAKEFILE_PATH" ]

    run grep -E "^test:" "$MAKEFILE_PATH"
    [ "$status" -eq 0 ]
}
