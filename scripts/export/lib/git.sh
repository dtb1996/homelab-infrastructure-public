#########################################
# Git
#########################################

git_commit_changes() {
    if [[ "$AUTO_COMMIT" != "true" ]]; then
        return
    fi

    echo "Checking Git configuration changes..."

    cd "$REPO_DIR"

    # Only stage exported configuration files
    git add configs/

    # Check if staged configuration changes exist
    if [[ -z "$(git diff --cached -- configs/)" ]]; then
        echo "No configuration changes detected."
        record_status "git" "NO CHANGES"
        return
    fi

    echo
    echo "Configuration changes:"

    git diff --cached --stat -- configs/
    git status --short configs/

    #########################################
    # Safety threshold
    #########################################

    MAX_CHANGED_LINES=5000

    CHANGED_LINES=$(git diff --cached --numstat -- configs/ \
        | awk '{added += $1; deleted += $2} END {print added + deleted}')

    if [[ -z "$CHANGED_LINES" ]]; then
        CHANGED_LINES=0
    fi

    if (( CHANGED_LINES > MAX_CHANGED_LINES )); then
        echo
        echo "ERROR: Git configuration change exceeds safety threshold."
        echo "Changed lines: $CHANGED_LINES"
        echo "Maximum allowed: $MAX_CHANGED_LINES"
        echo "Resetting staged changes."

        git reset configs/

        record_status "git" "BLOCKED"
        return 1
    fi

    #########################################
    # Commit
    #########################################

    echo
    echo "Creating Git commit..."

    git -c user.name="$GIT_USER_NAME" \
        -c user.email="$GIT_USER_EMAIL" \
        commit \
        -m "Automated configuration export $(date '+%Y-%m-%d %H:%M:%S')"

    if git push "$GIT_REMOTE" "$GIT_BRANCH"; then
        record_status "git" "COMMITTED"
    else
        echo "WARNING: Git push failed. Local commit preserved."
        record_status "git" "COMMITTED_PUSH_FAILED"
    fi
}
