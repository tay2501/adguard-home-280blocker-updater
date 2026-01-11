#!/bin/bash

# ==============================================================================
# 280blocker Updater for AdGuard Home
#
# Description:
#   Downloads the monthly adblock filter from 280blocker.net.
#   Designed to be run via cron. Follows "Silence is Golden" rule.
#   Optimized for Raspberry Pi (ARM) with SD card protection.
#
# Installation:
#   Script: /usr/local/bin/adguardhome-280blocker-filter-update (no extension)
#   Data:   /var/opt/adguardhome/filters/280blocker_domain_ag.txt
#
# Usage:
#   adguardhome-280blocker-filter-update [-v]
#   -v : Verbose mode (print progress to stdout)
#
# Exit Codes:
#   0 : Success (filter updated or no changes detected)
#   1 : Failure (download error, network issue, etc.)
#
# References:
#   - Google Shell Style Guide: https://google.github.io/styleguide/shellguide.html
#   - 280blocker: https://280blocker.net/
# ==============================================================================

# Bash Strict Mode
set -euo pipefail

# --- Constants & Configuration ---
# FHS Compliant: Variable data goes to /var/opt
readonly DATA_DIR="${DATA_DIR:-/var/opt/adguardhome/filters}"
readonly FILE_NAME="280blocker_domain_ag.txt"
readonly SAVE_PATH="${DATA_DIR}/${FILE_NAME}"

# Raspberry Pi Optimization: Use tmpfs (/tmp is usually mounted as tmpfs)
# This protects SD card from excessive writes
# Note: mktemp automatically respects TMPDIR environment variable
TEMP_FILE=$(mktemp)
readonly TEMP_FILE

# Network settings
readonly CONNECT_TIMEOUT=10
readonly MAX_TIMEOUT=30
readonly MAX_RETRIES=3
readonly RETRY_DELAY=5

# Minimum valid file size (bytes) - filter lists should be > 100 bytes
readonly MIN_FILE_SIZE=100

# Verbose flag
VERBOSE=0

# --- Helper Functions ---

# @description Print error message to stderr and optionally to syslog
# @arg $1 string Error message
# @exitcode None (does not exit)
error() {
  local msg="$1"
  echo "[ERROR] ${msg}" >&2

  # Log to syslog if available (common on Raspberry Pi)
  if command -v logger >/dev/null 2>&1; then
    logger -t "adguardhome-280blocker-filter-update" -p user.error "ERROR: ${msg}"
  fi
}

# @description Print info message to stdout in verbose mode
# @arg $1 string Info message
# @exitcode None
log() {
  if [[ "${VERBOSE}" -eq 1 ]]; then
    echo "[INFO] $1"
  fi
}

# @description Log successful operations to syslog
# @arg $1 string Success message
# @exitcode None
log_success() {
  local msg="$1"

  if command -v logger >/dev/null 2>&1; then
    logger -t "adguardhome-280blocker-filter-update" -p user.info "SUCCESS: ${msg}"
  fi

  log "$msg"
}

# @description Cleanup temporary files on exit
# @exitcode None
# shellcheck disable=SC2317  # Called via trap
cleanup() {
  rm -f "${TEMP_FILE}"
}
trap cleanup EXIT

# @description Error trap handler - provides stack trace on failure
# @exitcode None
# shellcheck disable=SC2317  # Called via trap
error_trap() {
  local line_no=$1
  local bash_lineno=${BASH_LINENO[0]}

  error "Script failed at line ${line_no} (bash line ${bash_lineno})"
  error "Last command: ${BASH_COMMAND}"

  if [[ "${VERBOSE}" -eq 1 ]]; then
    echo "[DEBUG] Call stack:" >&2
    local frame=0
    while caller "${frame}" >&2; do
      ((frame++))
    done
  fi
}
trap 'error_trap ${LINENO}' ERR

# @description Print usage information
# @exitcode 1
usage() {
  cat >&2 <<EOF
Usage: $0 [-v]

Options:
  -v    Verbose mode (print progress to stdout)

Examples:
  $0           # Run quietly (suitable for cron)
  $0 -v        # Run with verbose output

Exit Codes:
  0    Success (filter updated or no changes)
  1    Failure (download error, network issue)
EOF
  exit 1
}

# @description Download filter list from 280blocker.net with retry logic
# @arg $1 string Target date in YYYYMM format
# @return 0 on success, 1 on failure
# @exitcode 0 if download successful, 1 otherwise
download_list() {
  local target_date="$1"
  local url="https://280blocker.net/files/280blocker_domain_ag_${target_date}.txt"

  log "Attempting download from: ${url}"

  # Retry loop for unstable networks (e.g., Raspberry Pi on WiFi)
  local attempt=1
  while [ $attempt -le $MAX_RETRIES ]; do
    log "Download attempt ${attempt}/${MAX_RETRIES}"

    # curl options:
    # -f: Fail on HTTP errors
    # -s: Silent mode
    # -S: Show errors even in silent mode
    # -L: Follow redirects
    # --connect-timeout: Connection timeout
    # --max-time: Maximum time for the entire operation
    if curl -fsSL \
      --connect-timeout "$CONNECT_TIMEOUT" \
      --max-time "$MAX_TIMEOUT" \
      -o "$TEMP_FILE" \
      "$url"; then

      # Validation 1: File must not be empty
      if [ ! -s "$TEMP_FILE" ]; then
        log "Downloaded file is empty"
      # Validation 2: File must not be HTML error page
      elif grep -q "<!DOCTYPE html>" "$TEMP_FILE" 2>/dev/null; then
        log "Downloaded file appears to be HTML error page"
      # Validation 3: File must meet minimum size requirement
      else
        local file_size
        # BSD stat (macOS) vs GNU stat (Linux)
        file_size=$(stat -f%z "$TEMP_FILE" 2>/dev/null || stat -c%s "$TEMP_FILE" 2>/dev/null || echo "0")

        if [ "$file_size" -lt "$MIN_FILE_SIZE" ]; then
          log "Downloaded file is too small (${file_size} bytes < ${MIN_FILE_SIZE} bytes)"
        else
          log "Downloaded file validated (${file_size} bytes)"
          return 0
        fi
      fi
    else
      log "curl command failed with exit code $?"
    fi

    # Retry with exponential backoff
    if [ $attempt -lt $MAX_RETRIES ]; then
      local delay=$((RETRY_DELAY * attempt))
      log "Retrying in ${delay} seconds..."
      sleep "$delay"
    fi

    ((attempt++))
  done

  return 1
}

# @description Calculate target dates for filter download
# @stdout Prints CURRENT_MONTH and NEXT_MONTH in YYYYMM format
# @exitcode None
calculate_target_dates() {
  # ARM Optimization: Call date command only once to reduce overhead
  local current_date
  current_date=$(date +%Y%m%d)

  # Extract current month (YYYYMM)
  CURRENT_MONTH="${current_date:0:6}"

  # Calculate next month (handles year rollover correctly)
  NEXT_MONTH=$(date -d "${current_date:0:6}01 +1 month" "+%Y%m" 2>/dev/null || \
                date -v+1m -j -f "%Y%m%d" "${current_date:0:6}01" "+%Y%m" 2>/dev/null)
}

# --- Argument Parsing ---
while getopts "vh" opt; do
  case ${opt} in
    v) VERBOSE=1 ;;
    h) usage ;;
    *) usage ;;
  esac
done

# --- Main Logic ---

log "AdGuard Home 280blocker Updater starting"
log "Data directory: ${DATA_DIR}"
log "Target file: ${SAVE_PATH}"

# Calculate target dates
calculate_target_dates
log "Current month: ${CURRENT_MONTH}"
log "Next month: ${NEXT_MONTH}"

# Create data directory if missing
if [ ! -d "$DATA_DIR" ]; then
  log "Creating data directory: ${DATA_DIR}"
  mkdir -p "$DATA_DIR"
fi

# Download filter list (try next month first, fallback to current month)
if download_list "$NEXT_MONTH"; then
  log "Successfully downloaded next month's list (${NEXT_MONTH})"
elif download_list "$CURRENT_MONTH"; then
  log "Next month not available. Using current month's list (${CURRENT_MONTH})"
else
  error "Failed to download filter list. Neither ${NEXT_MONTH} nor ${CURRENT_MONTH} were available."
  error "Please check network connectivity and 280blocker.net availability."
  exit 1
fi

# Change detection: Skip write if content is identical (I/O optimization for SD cards)
if [ -f "$SAVE_PATH" ] && cmp -s "$TEMP_FILE" "$SAVE_PATH"; then
  log "No changes detected. Skipping update."
  log_success "Filter list is up to date"
  exit 0
fi

# Atomic file update with proper permissions
log "Updating filter list at ${SAVE_PATH}"

# Flexible permission handling: root vs non-root
if [ "$(id -u)" -eq 0 ]; then
  # Running as root: Set explicit ownership
  install -m 644 -o root -g root "$TEMP_FILE" "$SAVE_PATH"
  log "Installed with root ownership"
else
  # Running as non-root: Use current user's permissions
  install -m 644 "$TEMP_FILE" "$SAVE_PATH"
  log "Installed with current user ownership"
fi

log_success "Filter list updated successfully"

# Success: Silent exit (UNIX philosophy - silence is golden)
exit 0
