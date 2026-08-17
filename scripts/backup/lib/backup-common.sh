#!/bin/bash

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

#########################################
# Backup Common Library
#
# Version: 1.1
#
# Shared functions for backup scripts
#########################################

LIB_VERSION="1.1"


#########################################
# Logging
#########################################

log() {
    local msg="[$(date '+%F %T')] $1"

    if [[ -n "${LOGFILE:-}" ]]; then
        echo "$msg" | tee -a "$LOGFILE"
    else
        echo "$msg"
    fi
}


#########################################
# Error Handling
#########################################

backup_error_handler() {
    log "ERROR: Backup failed"
    log "Script : $(basename "$0")"
    log "Line: $1"
    log "Command: $2"
    exit 1
}

setup_error_handler() {
    set -E
    trap 'backup_error_handler $LINENO "$BASH_COMMAND"' ERR
}


#########################################
# Backup Header
#########################################

backup_header() {
    local name="$1"

    log "========================================="
    log "Starting ${name} backup"
    log "Version: ${VERSION}"
}


#########################################
# Backup Footer
#########################################

backup_footer() {
    log "Backup completed successfully"
    echo >> "$LOGFILE"
}


#########################################
# README Generator
#########################################

write_readme() {

cat > "$BASE/README.md" <<EOF
$README_TITLE

Directory Layout
----------------

archives/
    Backup archives.

databases/
    Database dumps.

inventories/
    System and application inventories.

latest/
    Symlinks to newest backups.

logs/
    Backup logs.

Retention
---------

Backups older than ${RETENTION_DAYS} days
are automatically removed.

Version
-------

${VERSION}

EOF

}


#########################################
# Create Latest Symlink
#########################################

create_latest_symlink() {

    local source="$1"
    local link="$2"

    ln -sfn "$source" "$link"

}


#########################################
# Rotate Backups
#########################################

rotate_backups() {

    local directory="$1"
    local pattern="$2"

    find "$directory" \
        -type f \
        -name "$pattern" \
        -mtime +"$RETENTION_DAYS" \
        -delete

}


#########################################
# Rotate Inventory Directories
#########################################

rotate_inventory() {

    local directory="$1"

    find "$directory" \
        -mindepth 1 \
        -maxdepth 1 \
        -type d \
        -mtime +"$RETENTION_DAYS" \
        -exec rm -rf {} +

}


#########################################
# Checksum Generator
#########################################

calculate_checksum() {

    local file="$1"

    sha256sum "$file" > "$file.sha256"

}


#########################################
# Inventory Directory
#########################################

create_inventory() {

    local name="$1"

    INV="$INV_DIR/$DATE"

    if [[ -n "${1:-}" ]]; then
        INV="$INV/$1"
    fi

    mkdir -p "$INV"

}


#########################################
# Write Backup Summary
#########################################
write_backup_summary() {
    local summary_file="$1"

    {
        echo "Backup Report"
        echo "====================="
        echo
        echo "Started:    $START_TIME"
        echo "Completed:  $END_TIME"
        echo "Duration:   ${ELAPSED}s"
        echo
        echo "Jobs"
        echo "----------------------------------------"

        for job in "${!JOB_RESULTS[@]}"; do
            printf "%-35s %-8s %5ss\n" \
                "$job" \
                "${JOB_RESULTS[$job]}" \
                "${JOB_TIMES[$job]}"
        done

        echo
        echo "Overall Status: $OVERALL_STATUS"
    } > "$summary_file"
}
