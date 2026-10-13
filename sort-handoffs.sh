#!/bin/sh
set -eu

projectsFile=${projectsFile:-${PROJECTS_FILE:-"$HOME/.config/ray/projects.tsv"}}
projectsRoot=${projectsRoot:-${PROJECTS_ROOT:-"$HOME/eclipse-workspace"}}

resolveProject() {
    name=$1
    value=$(awk -F '\t' -v name="$name" 'NR > 1 && $1 == name { print $2; exit }' "$projectsFile")
    [ -n "$value" ] || return 1
    case "$value" in
        "~") printf '%s\n' "$HOME" ;;
        "~/"*) printf '%s/%s\n' "$HOME" "${value#??}" ;;
        /*|[A-Za-z]:/*) printf '%s\n' "$value" ;;
        *) printf '%s/%s\n' "$projectsRoot" "$value" ;;
    esac
}

chatmap=$(resolveProject chatmap) || {
    echo "chatmap is not registered in $projectsFile" >&2
    exit 1
}

git -C "$chatmap" log --format='%ad' --date=short --name-only -- .llm/handoffs/ |
awk '/^[0-9-]{10}$/{d=$0} /\.md$/{if (!($0 in seen)) {print d, $0; seen[$0]=1}}' |
sort -r
