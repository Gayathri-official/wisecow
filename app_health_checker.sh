#!/usr/bin/env bash
#
# app_health_checker.sh
# Checks whether a web application is UP or DOWN by inspecting its
# HTTP status code, and logs / prints a report.
#
# Usage:
#   ./app_health_checker.sh https://example.com
#   ./app_health_checker.sh https://example.com --interval 30   # loop every 30s

set -euo pipefail

LOGFILE="/var/log/app_health_checker.log"
TIMEOUT=5           # seconds to wait for a response

log() {
    local ts
    ts=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$ts] $*" | tee -a "$LOGFILE" 2>/dev/null || echo "[$ts] $*"
}

check_url() {
    local url="$1"
    local http_code

    http_code=$(curl -o /dev/null -s -w "%{http_code}" --max-time "$TIMEOUT" "$url" || echo "000")

    if [[ "$http_code" =~ ^2[0-9]{2}$|^3[0-9]{2}$ ]]; then
        log "UP   - $url responded with HTTP $http_code"
        return 0
    else
        log "DOWN - $url responded with HTTP $http_code (or unreachable)"
        return 1
    fi
}

usage() {
    echo "Usage: $0 <url> [--interval <seconds>]"
    exit 1
}

main() {
    [ $# -ge 1 ] || usage
    local url="$1"
    local interval=""

    if [ "${2:-}" == "--interval" ]; then
        interval="${3:-}"
        [ -n "$interval" ] || usage
    fi

    if [ -n "$interval" ]; then
        while true; do
            check_url "$url" || true
            sleep "$interval"
        done
    else
        check_url "$url"
    fi
}

main "$@"
