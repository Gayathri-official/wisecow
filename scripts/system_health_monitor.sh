#!/usr/bin/env bash
#
# system_health_monitor.sh
# Monitors CPU, memory, disk usage and process count.
# Logs an ALERT line whenever a metric crosses its threshold.
#
# Usage: ./system_health_monitor.sh [--once]
#   --once   run a single check and exit (default: loop every INTERVAL sec)

set -euo pipefail

LOGFILE="/var/log/system_health_monitor.log"
INTERVAL=60          # seconds between checks (when running continuously)

CPU_THRESHOLD=80      # percent
MEM_THRESHOLD=80       # percent
DISK_THRESHOLD=80     # percent (per mounted filesystem)
MAX_PROCESSES=500      # sanity threshold for total running processes

log() {
    local level="$1"; shift
    local msg="$*"
    local ts
    ts=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$ts] [$level] $msg" | tee -a "$LOGFILE"
}

check_cpu() {
    # 100 - idle% gives current CPU utilisation
    local idle usage
    idle=$(top -bn1 | grep "Cpu(s)" | awk -F',' '{print $4}' | awk '{print $1}')
    usage=$(awk -v idle="$idle" 'BEGIN{printf "%.0f", 100-idle}')
    if [ "$usage" -ge "$CPU_THRESHOLD" ]; then
        log "ALERT" "High CPU usage: ${usage}% (threshold ${CPU_THRESHOLD}%)"
    else
        log "OK" "CPU usage: ${usage}%"
    fi
}

check_memory() {
    local total used usage
    read -r total used <<< "$(free -m | awk '/Mem:/ {print $2, $3}')"
    usage=$(awk -v u="$used" -v t="$total" 'BEGIN{printf "%.0f", (u/t)*100}')
    if [ "$usage" -ge "$MEM_THRESHOLD" ]; then
        log "ALERT" "High Memory usage: ${usage}% (threshold ${MEM_THRESHOLD}%)"
    else
        log "OK" "Memory usage: ${usage}%"
    fi
}

check_disk() {
    # Check every real mounted filesystem
    while read -r line; do
        local usage mount
        usage=$(echo "$line" | awk '{print $5}' | tr -d '%')
        mount=$(echo "$line" | awk '{print $6}')
        if [ "$usage" -ge "$DISK_THRESHOLD" ]; then
            log "ALERT" "High Disk usage on $mount: ${usage}% (threshold ${DISK_THRESHOLD}%)"
        else
            log "OK" "Disk usage on $mount: ${usage}%"
        fi
    done < <(df -h -x tmpfs -x devtmpfs | tail -n +2)
}

check_processes() {
    local count
    count=$(ps -e --no-headers | wc -l)
    if [ "$count" -ge "$MAX_PROCESSES" ]; then
        log "ALERT" "High process count: $count (threshold $MAX_PROCESSES)"
    else
        log "OK" "Running processes: $count"
    fi
}

run_checks() {
    log "INFO" "----- Health check started -----"
    check_cpu
    check_memory
    check_disk
    check_processes
    log "INFO" "----- Health check finished -----"
}

main() {
    touch "$LOGFILE" 2>/dev/null || LOGFILE="./system_health_monitor.log"

    if [ "${1:-}" == "--once" ]; then
        run_checks
        exit 0
    fi

    while true; do
        run_checks
        sleep "$INTERVAL"
    done
}

main "$@"
