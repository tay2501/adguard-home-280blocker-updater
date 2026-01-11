#!/bin/bash

# ==============================================================================
# 280blocker Updater (FHS Compliant & UNIX Philosophy)
#
# Description:
#   Downloads the monthly adblock filter from 280blocker.net.
#   Designed to be run via cron. Follows "Silence is Golden" rule.
#
# Location:
#   Script: /usr/local/bin/update_280.sh
#   Data:   /var/opt/adguardhome/filters/280blocker_domain.txt
#
# Usage:
#   update_280.sh [-v]
#   -v : Verbose mode (print progress to stdout)
# ==============================================================================

# Bash Strict Mode
set -euo pipefail

# --- Constants & Configuration ---
# FHS準拠: 変動データは /var/opt に置く
DATA_DIR="/var/opt/adguardhome/filters"
FILE_NAME="280blocker_domain.txt"
SAVE_PATH="${DATA_DIR}/${FILE_NAME}"
TEMP_FILE=$(mktemp)
VERBOSE=0

# --- Helper Functions ---

# エラーメッセージは標準エラー出力(stderr)へ
error() {
    echo "[ERROR] $1" >&2
}

# 冗長モード時のみ標準出力へ
log() {
    if [ "$VERBOSE" -eq 1 ]; then
        echo "[INFO] $1"
    fi
}

cleanup() {
    rm -f "$TEMP_FILE"
}
trap cleanup EXIT

usage() {
    echo "Usage: $0 [-v]" >&2
    exit 1
}

# --- Argument Parsing ---
while getopts "v" opt; do
    case ${opt} in
        v) VERBOSE=1 ;;
        *) usage ;;
    esac
done

# --- Main Logic ---

# 日付計算: 今月1日の1ヶ月後 (13月問題回避ロジック)
NEXT_MONTH=$(date -d "$(date +%Y-%m-01) +1 month" "+%Y%m")
CURRENT_MONTH=$(date "+%Y%m")

# ディレクトリ準備
if [ ! -d "$DATA_DIR" ]; then
    log "Creating data directory: $DATA_DIR"
    mkdir -p "$DATA_DIR"
fi

download_list() {
    local target_date="$1"
    local url="https://280blocker.net/files/280blocker_domain_ag_${target_date}.txt"
    
    log "Attempting download from: $url"
    
    # curl: -f(fail on error), -s(silent), -S(show error on fail), -L(follow redirect)
    if curl -fsSL --connect-timeout 10 -o "$TEMP_FILE" "$url"; then
        # 検証: 空ファイルやHTMLエラーページでないか
        if [ -s "$TEMP_FILE" ] && ! grep -q "<!DOCTYPE html>" "$TEMP_FILE"; then
            return 0
        fi
    fi
    return 1
}

# トライアル処理
if download_list "$NEXT_MONTH"; then
    log "Downloaded next month's list ($NEXT_MONTH)."
elif download_list "$CURRENT_MONTH"; then
    log "Next month not found. Fallback to current month ($CURRENT_MONTH)."
else
    error "Failed to download filter list. Neither ${NEXT_MONTH} nor ${CURRENT_MONTH} were available."
    exit 1
fi

# 変更検知 (diff)
# 既に同じファイルがある場合は書き込みを行わない (I/O節約)
if [ -f "$SAVE_PATH" ] && cmp -s "$TEMP_FILE" "$SAVE_PATH"; then
    log "No changes detected. Skipping update."
else
    log "Updating filter list at $SAVE_PATH"
    # アトミック更新: installコマンドで権限設定と移動を同時に行う
    install -m 644 -o root -g root "$TEMP_FILE" "$SAVE_PATH"
    log "Update complete."
fi

# 成功時は黙って終了 (Exit code 0)
exit 0