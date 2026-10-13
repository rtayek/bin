#!/bin/sh
set -eu

projectsFile=${projectsFile:-${PROJECTS_FILE:-"$HOME/.config/ray/projects.tsv"}}
projectsRoot=${projectsRoot:-${PROJECTS_ROOT:-"$HOME/eclipse-workspace"}}

[ -f "$projectsFile" ] || {
    echo "Project registry not found: $projectsFile" >&2
    exit 1
}

resolvePath() {
    value=$1
    case "$value" in
        "~") printf '%s\n' "$HOME" ;;
        "~/"*) printf '%s/%s\n' "$HOME" "${value#??}" ;;
        /*|[A-Za-z]:/*) printf '%s\n' "$value" ;;
        *) printf '%s/%s\n' "$projectsRoot" "$value" ;;
    esac
}

tab=$(printf '\t')
awk -F "$tab" 'NR > 1 { print $1 "|" $2 }' "$projectsFile" |
while IFS='|' read -r name value; do
    repo=$(resolvePath "$value")
    echo "=== $name ==="
    if [ ! -d "$repo" ]; then
        echo "missing: $repo"
    elif [ ! -e "$repo/.git" ]; then
        echo "not a Git working tree: $repo"
    else
        git -C "$repo" status
    fi
    echo
done
