#!/bin/bash

# ==============================================================================
# AdGuard Home 280blocker Filter Updater
#
# Description:
#   Downloads the monthly adblock filter from 280blocker.net.
#   Designed for Raspberry Pi (SD Card protection) and AdGuard Home.
#
# Standards:
#   - Google Shell Style Guide compliant
#   - FHS (Filesystem Hierarchy Standard) compliant
#   - Silence is Golden (for Cron/Systemd)
# ==============================================================================

# Bash Strict Mode
set -euo pipefail
IFS=$'\n\t'

# --- Constants & Configuration ---
readonly SCRIPT_NAME="adguardhome-280blocker-filter-updater"
readonly DATA_DIR="${DATA_DIR:-/var/opt/adguardhome/filters}"
readonly FILE_NAME="280blocker_domain_ag.txt"
readonly SAVE_PATH="${DATA_DIR}/${FILE_NAME}"

# Network settings
readonly CONNECT_TIMEOUT=10
readonly MAX_TIMEOUT=30
readonly MAX_RETRIES=3
readonly RETRY_DELAY=5
readonly MIN_FILE_SIZE=100

# State variables
VERBOSE=0

# --- Helper Functions ---

# @description Print message to stderr and syslog
# @arg $1 string Error message
err() {
  local msg="[ERROR] $1"
  printf '%s\n' "${msg}" >&2
  if command -v logger >/dev/null 2>&1; then
    logger -t "${SCRIPT_NAME}" -p user.err "${msg}"
  fi
}

# @description Print info message to stdout if verbose mode is on
# @arg $1 string Message
info() {
  if [[ "${VERBOSE}" -eq 1 ]]; then
    printf '[INFO] %s\n' "$1"
  fi
}

# @description Log success to syslog and stdout
# @arg $1 string Message
log_success() {
  local msg="SUCCESS: $1"
  if command -v logger >/dev/null 2>&1; then
    logger -t "${SCRIPT_NAME}" -p user.info "${msg}"
  fi
  info "$msg"
}

# @description Cleanup temporary files
cleanup() {
  if [[ -n "${TEMP_FILE:-}" && -f "${TEMP_FILE}" ]]; then
    rm -f "${TEMP_FILE}"
  fi
}
trap cleanup EXIT

# @description Provide debug info on error
error_trap() {
  local res=$?
  local line_no=$1
  err "Command '${BASH_COMMAND}' failed at line ${line_no} with exit code ${res}"
}
trap 'error_trap ${LINENO}' ERR

# --- Logic Functions ---

# @description Download filter list with retry logic
# @arg $1 string Target date in YYYYMM format
download_filter() {
  local target_date="$1"
  local url="https://280blocker.net/files/280blocker_domain_ag_${target_date}.txt"
  local attempt=1

  info "Fetching from: ${url}"

  while (( attempt <= MAX_RETRIES )); do
    info "Attempt ${attempt}/${MAX_RETRIES}"

    if curl -fsSL \
      --connect-timeout "${CONNECT_TIMEOUT}" \
      --max-time "${MAX_TIMEOUT}" \
      -o "${TEMP_FILE}" \
      "${url}"; then

      # Validation: Basic file sanity checks
      if [[ ! -s "${TEMP_FILE}" ]]; then
        info "Download successful but file is empty."
      elif grep -q "<!DOCTYPE html>" "${TEMP_FILE}" 2>/dev/null; then
        info "Downloaded file is an HTML error page."
      else
        local size
        size=$(stat -c%s "${TEMP_FILE}" 2>/dev/null || stat -f%z "${TEMP_FILE}" 2>/dev/null || echo 0)
        if (( size < MIN_FILE_SIZE )); then
          info "File too small: ${size} bytes."
        else
          info "Download validated: ${size} bytes."
          return 0
        fi
      fi
    fi

    if (( attempt < MAX_RETRIES )); then
      local delay=$((RETRY_DELAY * attempt))
      info "Retrying in ${delay} seconds..."
      sleep "${delay}"
    fi
    (( attempt++ ))
  done

  return 1
}

# @description Safely calculate current and next month in YYYYMM format
calculate_dates() {
  # Note: Use day 01 to avoid '+1 month' bug on 31st
  local today_01
  today_01=$(date +%Y-%m-01)
  
  CURRENT_MONTH=$(date -d "${today_01}" +%Y%m)
  # Compatibility: GNU date (Linux) vs BSD date (macOS)
  NEXT_MONTH=$(date -d "${today_01} +1 month" +%Y%m 2>/dev/null || \
                date -v+1m -f "%Y-%m-%d" "${today_01}" +%Y%m 2>/dev/null)
}

usage() {
  cat <<EOF >&2
Usage: ${0##*/} [-v] [-h]

Options:
  -v    Verbose mode
  -h    Show help
EOF
  exit 1
}

# --- Main ---

while getopts "vh" opt; do
  case "${opt}" in
    v) VERBOSE=1 ;;
    h) usage ;;
    *) usage ;;
  esac
done

# Prepare environment
calculate_dates
TEMP_FILE=$(mktemp)
readonly TEMP_FILE

info "Starting update process..."

# 1. Download (Try Next Month, then Current Month)
if download_filter "${NEXT_MONTH}"; then
  info "Target: Next Month (${NEXT_MONTH})"
elif download_filter "${CURRENT_MONTH}"; then
  info "Target: Current Month (${CURRENT_MONTH})"
else
  err "Failed to download any valid filter list from 280blocker.net."
  exit 1
fi

# 2. Change Detection (SD Card Protection)
if [[ -f "${SAVE_PATH}" ]] && cmp -s "${TEMP_FILE}" "${SAVE_PATH}"; then
  log_success "No changes detected. Skipping I/O operations."
  exit 0
fi

# 3. Directory Management
if [[ ! -d "${DATA_DIR}" ]]; then
  info "Creating directory: ${DATA_DIR}"
  mkdir -p "${DATA_DIR}"
fi

# 4. Atomic Update
info "Applying update to ${SAVE_PATH}"
if [[ "$(id -u)" -eq 0 ]]; then
  # Root: Ensure correct ownership for AGH
  install -m 644 -o root -g root "${TEMP_FILE}" "${SAVE_PATH}"
else
  # Non-root: Standard install
  install -m 644 "${TEMP_FILE}" "${SAVE_PATH}"
fi

log_success "Filter list updated successfully."
exit 0