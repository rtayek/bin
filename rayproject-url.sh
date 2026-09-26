#!/usr/bin/env bash

set -euo pipefail

uri=${1:-}
case "$uri" in
    rayproject://*) ;;
    *)
        echo "error: unsupported URL: $uri" >&2
        exit 2
        ;;
esac

project=${uri#rayproject://}
project=${project%%[/?#]*}
[ -n "$project" ] || { echo "error: missing project name" >&2; exit 2; }

projectsFile=${projectsFile:-${PROJECTS_FILE:-"$HOME/.config/ray/projects.tsv"}}
[ -f "$projectsFile" ] || { echo "error: missing project registry: $projectsFile" >&2; exit 1; }

match=$(
    awk -F '\t' -v project="$project" '
        NR > 1 && $1 == project {
            print $2 "|" $3 "|" $4
            exit
        }
    ' "$projectsFile"
)

[ -n "$match" ] || { echo "error: project not registered: $project" >&2; exit 1; }
projectPath=${match%%|*}
rest=${match#*|}
port=${rest%%|*}
projectColor=${rest#*|}

case "$projectPath" in
    "~/"*) projectDir="$HOME/${projectPath#??}" ;;
    *) projectDir="$projectPath" ;;
esac

[ -n "$port" ] || { echo "error: no webterm port registered for $project" >&2; exit 1; }
[ -n "$projectColor" ] || { echo "error: no terminal color registered for $project" >&2; exit 1; }

exec bash "$HOME/bin/launch-bash-boxes.sh" --kill "$projectColor" "$projectDir"
