#!/bin/sh
# Audit every Git repository below a directory.
# Default directory is the current directory.

set -u

directory=${1:-.}

if [ ! -d "$directory" ]; then
    printf 'error: directory not found: %s\n' "$directory" >&2
    exit 2
fi

if ! command -v audit-repo-env.sh >/dev/null 2>&1; then
    printf 'error: audit-repo-env.sh not found on PATH\n' >&2
    exit 2
fi

root=$(cd "$directory" && pwd) || exit 2

printf 'Scanning for Git repositories under:\n'
printf '  %s\n\n' "$root"

find "$root" -type d -name .git -prune -print |
while IFS= read -r gitdir
do
    repo=${gitdir%/.git}

    printf '\n'
    printf '============================================================\n'
    printf '%s\n' "$repo"
    printf '============================================================\n'

    audit-repo-env.sh "$repo"

    status=$?
    if [ "$status" -ne 0 ]; then
        printf 'WARNING: audit failed for %s (status %s)\n' \
            "$repo" "$status" >&2
    fi
done