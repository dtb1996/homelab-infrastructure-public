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

    pct exec "$ct" -- cat "$src" > "$dest"
}

copy_pct_dir() {
    local ct="$1"
    local src="$2"
    local dest="$3"

    mkdir -p "$dest"

    echo "Copying directory: CT${ct}:${src}"

    pct exec "$ct" -- \
        tar -C "$(dirname "$src")" -cf - "$(basename "$src")" \
        | tar -C "$dest" -xf -
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
