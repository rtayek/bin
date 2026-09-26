#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  new-project.sh <name> [target-dir] [port]
  new-project.sh -h
  new-project.sh --help

Arguments:
  name        Project name, for example five-rules
  target-dir  Default: ~/eclipse-workspace/<name>
  port        Reuse registered port, otherwise next unused webterm port
EOF
}

case "${1:-}" in
    -h|--help)
        usage
        exit 0
        ;;
    "")
        usage >&2
        exit 2
        ;;
    -*)
        echo "new-project.sh: invalid project name: $1" >&2
        usage >&2
        exit 2
        ;;
esac

dotfiles="$HOME/dotfiles"
dotmdfiles="$HOME/eclipse-workspace/dotmdfiles"
systemRoot="$HOME/eclipse-workspace/system"
defaultProjectsFile="$systemRoot/projects.tsv"
projectsFile=${projectsFile:-${PROJECTS_FILE:-"$defaultProjectsFile"}}
macro="$dotfiles/templates/project-home.html.macro"

name=$1
directory=${2:-"$HOME/eclipse-workspace/$name"}
port=${3:-}

[ -f "$projectsFile" ] || { echo "missing $projectsFile" >&2; exit 1; }
[ -f "$macro" ] || { echo "missing $macro" >&2; exit 1; }
[ -x "$dotmdfiles/bin/setup-project.sh" ] ||
    { echo "missing $dotmdfiles/bin/setup-project.sh" >&2; exit 1; }

existing=$(
    awk -F '\t' -v name="$name" 'NR > 1 && $1 == name { print $2 "|" $3 "|" $4; exit }' "$projectsFile"
)

if [ -n "$existing" ]; then
    registeredPath=${existing%%|*}
    rest=${existing#*|}
    existingPort=${rest%%|*}
    existingColor=${rest#*|}

    if [ -n "$port" ] && [ -n "$existingPort" ] && [ "$port" != "$existingPort" ]; then
        echo "error: $name is already registered on port $existingPort" >&2
        exit 1
    fi
    port=${existingPort:-$port}
    color=$existingColor
else
    if [ -z "$port" ]; then
        port=$(
            awk -F '\t' 'NR > 1 && $3 ~ /^[0-9]+$/ && $3 + 0 > max { max=$3 + 0 } END { print (max ? max + 1 : 1031) }' "$projectsFile"
        )
    elif awk -F '\t' -v port="$port" 'NR > 1 && $3 == port { found=1 } END { exit !found }' "$projectsFile"
    then
        echo "error: port $port is already registered to another project" >&2
        exit 1
    fi

    colors=(Red Green Blue Cyan Magenta Yellow)
    index=$(( (port - 1031) % ${#colors[@]} ))
    (( index < 0 )) && index=$((index + ${#colors[@]}))
    color=${colors[$index]}

    case "$directory" in
        "$HOME"/*) registryPath="~/${directory#"$HOME"/}" ;;
        *) registryPath="$directory" ;;
    esac

    [ -z "$(tail -c1 "$projectsFile")" ] || printf '\n' >> "$projectsFile"
    printf '%s\t%s\t%s\t%s\t\t\n' "$name" "$registryPath" "$port" "$color" >> "$projectsFile"
fi

if [ "$projectsFile" = "$defaultProjectsFile" ]; then
    sh "$systemRoot/deploy-projects.sh"
fi

[ -n "$port" ] || { echo "error: project has no webterm port: $name" >&2; exit 1; }
[ -n "$color" ] || { echo "error: project has no terminal color: $name" >&2; exit 1; }

echo "Project:    $name"
echo "Directory:  $directory"
echo "Port:       $port"
echo "Color:      $color"
echo

echo "-- setup-project.sh --"
"$dotmdfiles/bin/setup-project.sh" "$directory"
echo

homeHtml="$directory/project-home.html"
if [ -e "$homeHtml" ]; then
    echo "-- $homeHtml already exists, skipping --"
else
    echo "-- generating $homeHtml --"
    sed \
        -e "s|PROJECT_NAME|$name|g" \
        -e "s|BASH_URL|http://127.0.0.1:$port/|g" \
        -e "s|CHATGPT_URL|https://chatgpt.com/|g" \
        -e "s|CLAUDE_URL|https://claude.ai/|g" \
        -e "s|GITHUB_URL|https://github.com/rtayek/$name|g" \
        "$macro" > "$homeHtml"
fi
echo

envrc="$directory/.envrc"
if [ -e "$envrc" ]; then
    if grep -q PROJECT_TERMINAL_NAME "$envrc"; then
        echo "-- $envrc already sets PROJECT_TERMINAL_NAME, skipping --"
    else
        echo "-- appending PROJECT_TERMINAL_NAME to existing $envrc --"
        {
            printf 'PROJECT_TERMINAL_NAME=%s\n' "$name"
            echo 'export PROJECT_TERMINAL_NAME'
        } >> "$envrc"
    fi
else
    echo "-- generating $envrc --"
    cat > "$envrc" <<EOF
source ~/dotfiles/direnv/envrc
useProjectHistory
PROJECT_TERMINAL_NAME=$name
export PROJECT_TERMINAL_NAME
EOF
fi

echo
echo "Done. Remaining manual steps:"
echo "  - run 'direnv allow' in $directory"
echo "  - run ~/dotfiles/bin/launch-webterms.sh if the webterm is not already running"
echo "  - create a Chrome tab group and add $homeHtml as the anchor tab"
echo "  - commit and push projects.tsv in System if the registry changed"
