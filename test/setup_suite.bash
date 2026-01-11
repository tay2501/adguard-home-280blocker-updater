#!/usr/bin/env bash
# setup_suite.bash - Test suite setup for bats-core
# This file is sourced before running the test suite

# Set strict mode for test environment
set -euo pipefail

# Test environment variables
export TEST_SUITE_NAME="AdGuard Home 280blocker Updater"
export BATS_TEST_TIMEOUT=30

# Helper function: Print test suite info
setup_suite() {
    echo "# ========================================" >&3
    echo "# ${TEST_SUITE_NAME}" >&3
    echo "# bats-core version: $(bats --version 2>/dev/null || echo 'not installed')" >&3
    echo "# ========================================" >&3
}

# Helper function: Cleanup after all tests
teardown_suite() {
    echo "# Test suite completed" >&3
}
