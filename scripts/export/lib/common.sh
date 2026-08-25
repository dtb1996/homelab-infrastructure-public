SYNC_RESULTS=()

#########################################
# Helpers
#########################################

record_status() {
    local service="$1"
    local status="$2"

    SYNC_RESULTS+=("[$status] $service")
}

run_command() {
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[DRY RUN] $*"
    else
        eval "$@"
    fi
}

copy_pct_file() {
    local ct="$1"
    local src="$2"
    local dest="$3"

    mkdir -p "$(dirname "$dest")"

    echo "Copying file: CT${ct}:${src}"

    if ! pct exec "$ct" -- cat "$src" > "$dest"; then
        echo "ERROR: Failed to copy CT${ct}:${src}"
        return 1
    fi

    return 0
}

copy_pct_dir() {
    local ct="$1"
    local src="$2"
    local dest="$3"

    mkdir -p "$dest"

    echo "Copying directory: CT${ct}:${src}"

    if ! pct exec "$ct" -- \
        tar -C "$(dirname "$src")" -cf - "$(basename "$src")" \
        | tar -C "$dest" -xf -; then

        echo "ERROR: Failed to copy CT${ct}:${src}"
        return 1
    fi

    return 0
}

is_lxc_running() {
    local CTID="$1"

    pct status "$CTID" 2>/dev/null | grep -q "status: running"
}

#########################################
# Dependency Checks
#########################################

check_dependencies() {
    for cmd in pct tar git sed awk; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            echo "ERROR: Required command '$cmd' not found."
            return 1
        fi
    done

    return 0
}

#########################################
# Finish Handler
#########################################

finish() {
    local status=$?

    echo
    echo "========================================"

    if [[ $status -eq 0 ]]; then
        echo "Configuration Export Complete"
    else
        echo "Configuration Export FAILED (exit code $status)"
    fi

    echo "Completed: $(date)"
    echo "========================================"
}
