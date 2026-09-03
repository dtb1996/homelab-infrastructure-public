#!/bin/bash
set -euo pipefail

#########################################
# Backup Orchestrator
#
# Version: 1.7
#########################################

VERSION="1.6"

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

BASE="/srv/backups"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$BASE/logs"

LOGFILE="$LOG_DIR/backup-all.log"
LOCKFILE="$BASE/.backup.lock"

STATUS_DIR="$LOG_DIR/status"

SUMMARY_FILE="$LOG_DIR/backup-summary.json"
REPORT_FILE="$LOG_DIR/backup-summary.txt"
STATUS_FILE="$STATUS_DIR/latest.json"

FAILED=0

export LOGFILE

mkdir -p "$LOG_DIR" "$STATUS_DIR"

# Load Common Library
source "$SCRIPT_DIR/lib/backup-common.sh"

setup_error_handler

#########################################
# Diagnostics
#########################################

log "Running as: $(whoami)"
log "Hostname: $(hostname)"
log "PWD: $(pwd)"
log "PATH: $PATH"

log "Date: $(date)"

log "pct: $(command -v pct || echo missing)"
log "tar: $(command -v tar || echo missing)"
log "find: $(command -v find || echo missing)"

log "Running as PID $$"
id | tee -a "$LOGFILE"

START=$(date +%s)
START_TIME=$(date '+%F %T')

#########################################
# Acquire backup lock
#########################################

exec 200>"$LOCKFILE"

if ! flock -n 200; then
    log "Another backup process is already running."
    exit 1
fi

#########################################
# Job tracking
#########################################

declare -A JOB_RESULTS
declare -A JOB_TIMES

run_backup() {

    NAME="$1"
    SCRIPT="$2"

    JOB_ID=$(echo "$NAME" | tr ' ' '_' | tr '[:upper:]' '[:lower:]')
    JOB_STATUS_FILE="$STATUS_DIR/$JOB_ID.status"

    log "------------------------------------------"
    log "Starting job: $NAME"

    JOB_START=$(date +%s)

    echo "STARTED $(date)" > "$JOB_STATUS_FILE"

    if [[ ! -x "$SCRIPT" ]]; then

        log "ERROR: Script not found or not executable: $SCRIPT"

        echo "FAILED $(date)" >> "$JOB_STATUS_FILE"

        JOB_RESULTS["$NAME"]="failed"
        JOB_TIMES["$NAME"]=0

        FAILED=1
        return

    fi


    if "$SCRIPT"; then

        JOB_END=$(date +%s)
        JOB_TIME=$((JOB_END - JOB_START))

        echo "SUCCESS $(date)" >> "$JOB_STATUS_FILE"

        JOB_RESULTS["$NAME"]="success"
        JOB_TIMES["$NAME"]="$JOB_TIME"

        log "Completed job: $NAME (${JOB_TIME}s)"

    else

        JOB_END=$(date +%s)
        JOB_TIME=$((JOB_END - JOB_START))

        echo "FAILED $(date)" >> "$JOB_STATUS_FILE"

        JOB_RESULTS["$NAME"]="failed"
        JOB_TIMES["$NAME"]="$JOB_TIME"

        FAILED=1

        log "FAILED job: $NAME (${JOB_TIME}s)"

    fi
}

#########################################
# Start backup
#########################################

log "=========================================="
log "Starting Backup"
log "Version: $VERSION"

#########################################
# Backup Jobs
#########################################

run_backup \
    "Proxmox configuration backup" \
    "$SCRIPT_DIR/backup-proxmox-config.sh"

run_backup \
    "Home Assistant backup" \
    "$SCRIPT_DIR/backup-homeassistant.sh"

run_backup \
    "Raspberry Pi backup" \
    "$SCRIPT_DIR/backup-raspberrypi.sh"

run_backup \
    "Docker configuration backup" \
    "$SCRIPT_DIR/backup-docker-config.sh"

run_backup \
    "Paperless backup" \
    "$SCRIPT_DIR/backup-paperless.sh"

run_backup \
    "SSD to USB backup mirror" \
    "$SCRIPT_DIR/mirror-backups.sh"

#########################################
# Generate Summary
#########################################

END=$(date +%s)
END_TIME=$(date '+%F %T')
ELAPSED=$((END - START))


if [ "$FAILED" -eq 0 ]; then
    OVERALL_STATUS="success"
else
    OVERALL_STATUS="failed"
fi

#########################################
# JSON Summary
#########################################

{
cat <<EOF
{
  "backup_version": "$VERSION",
  "hostname": "$(hostname)",
  "started": "$START_TIME",
  "completed": "$END_TIME",
  "duration_seconds": $ELAPSED,
  "status": "$OVERALL_STATUS",
  "jobs": {
EOF

FIRST=true

for JOB in "${!JOB_RESULTS[@]}"; do

    if [ "$FIRST" = true ]; then
        FIRST=false
    else
        echo ","
    fi

    cat <<EOF
    "$JOB": {
      "status": "${JOB_RESULTS[$JOB]}",
      "duration_seconds": ${JOB_TIMES[$JOB]}
    }
EOF

done

cat <<EOF

  },
  "failed_jobs": [
EOF


FIRST=true

for JOB in "${!JOB_RESULTS[@]}"; do

    if [ "${JOB_RESULTS[$JOB]}" = "failed" ]; then

        if [ "$FIRST" = true ]; then
            FIRST=false
        else
            echo ","
        fi

        echo -n "    \"$JOB\""

    fi

done


cat <<EOF

  ]
}
EOF

} > "$SUMMARY_FILE"

#########################################
# Publish Backup Status
#########################################

cp "$SUMMARY_FILE" "$STATUS_FILE"

log "Published backup status: $STATUS_FILE"

#########################################
# Human-readable Summary
#########################################

write_backup_summary "$REPORT_FILE"

#########################################
# Log Summary
#########################################

log "=========================================="
log "Backup Summary"

for JOB in "${!JOB_RESULTS[@]}"; do
    log "$JOB: ${JOB_RESULTS[$JOB]} (${JOB_TIMES[$JOB]}s)"
done

log "Total runtime: ${ELAPSED}s"
log "JSON summary: $SUMMARY_FILE"
log "Report summary: $REPORT_FILE"


if [ "$FAILED" -eq 0 ]; then

    log "Backup completed successfully"
    echo >> "$LOGFILE"
    exit 0

else

    log "Backup completed with failures"
    echo >> "$LOGFILE"
    exit 1

fi
