#!/usr/bin/env bash
# new-project.sh - wire a new project up to the standard set of tools.
#
# Runs, in order:
#   1. dotmdfiles/bin/setup-project.sh
#   2. reuse or allocate project registry port/color
#   3. project-home.html generated from the dotfiles template
#   4. .envrc with PROJECT_TERMINAL_NAME

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

DOTFILES="$HOME/dotfiles"
DOTMDFILES="$HOME/eclipse-workspace/dotmdfiles"
REGISTRY="${PROJECTS_FILE:-$DOTMDFILES/projects.txt}"
MACRO="$DOTFILES/templates/project-home.html.macro"

NAME="$1"
DIR="${2:-$HOME/eclipse-workspace/$NAME}"
PORT="${3:-}"

[ -f "$REGISTRY" ] || { echo "missing $REGISTRY" >&2; exit 1; }
[ -f "$MACRO" ] || { echo "missing $MACRO" >&2; exit 1; }
[ -x "$DOTMDFILES/bin/setup-project.sh" ] ||
  { echo "missing $DOTMDFILES/bin/setup-project.sh" >&2; exit 1; }

existing=$(
  awk -F'|' -v name="$NAME" '$1 == name { print $2 "|" $3 "|" $4; exit }' "$REGISTRY"
)

if [ -n "$existing" ]; then
  registered_path=${existing%%|*}
  rest=${existing#*|}
  existing_port=${rest%%|*}
  existing_color=${rest#*|}

  if [ -n "$PORT" ] && [ -n "$existing_port" ] && [ "$PORT" != "$existing_port" ]; then
    echo "error: $NAME is already registered on port $existing_port" >&2
    exit 1
  fi
  PORT=${existing_port:-$PORT}
  COLOR=$existing_color
else
  if [ -z "$PORT" ]; then
    PORT=$(
      awk -F'|' '$3 ~ /^[0-9]+$/ && $3 + 0 > max { max=$3 + 0 } END { print (max ? max + 1 : 1031) }' "$REGISTRY"
    )
  elif awk -F'|' -v port="$PORT" '$3 == port { found=1 } END { exit !found }' "$REGISTRY"
  then
    echo "error: port $PORT is already registered to another project" >&2
    exit 1
  fi

  colors=(Red Green Blue Cyan Magenta Yellow)
  index=$(( (PORT - 1031) % ${#colors[@]} ))
  (( index < 0 )) && index=$((index + ${#colors[@]}))
  COLOR=${colors[$index]}

  case "$DIR" in
    "$HOME"/*) registry_path="~/${DIR#"$HOME"/}" ;;
    *) registry_path="$DIR" ;;
  esac

  [ -z "$(tail -c1 "$REGISTRY")" ] || printf '\n' >> "$REGISTRY"
  printf '%s|%s|%s|%s||\n' "$NAME" "$registry_path" "$PORT" "$COLOR" >> "$REGISTRY"
fi

[ -n "$PORT" ] || { echo "error: project has no webterm port: $NAME" >&2; exit 1; }
[ -n "$COLOR" ] || { echo "error: project has no terminal color: $NAME" >&2; exit 1; }

echo "Project:    $NAME"
echo "Directory:  $DIR"
echo "Port:       $PORT"
echo "Color:      $COLOR"
echo

echo "-- setup-project.sh --"
"$DOTMDFILES/bin/setup-project.sh" "$DIR"
echo

HOME_HTML="$DIR/project-home.html"
if [ -e "$HOME_HTML" ]; then
  echo "-- $HOME_HTML already exists, skipping --"
else
  echo "-- generating $HOME_HTML --"
  sed \
    -e "s|PROJECT_NAME|$NAME|g" \
    -e "s|BASH_URL|http://127.0.0.1:$PORT/|g" \
    -e "s|CHATGPT_URL|https://chatgpt.com/|g" \
    -e "s|CLAUDE_URL|https://claude.ai/|g" \
    -e "s|GITHUB_URL|https://github.com/rtayek/$NAME|g" \
    "$MACRO" > "$HOME_HTML"
fi
echo

ENVRC="$DIR/.envrc"
if [ -e "$ENVRC" ]; then
  if grep -q PROJECT_TERMINAL_NAME "$ENVRC"; then
    echo "-- $ENVRC already sets PROJECT_TERMINAL_NAME, skipping --"
  else
    echo "-- appending PROJECT_TERMINAL_NAME to existing $ENVRC --"
    {
      printf 'PROJECT_TERMINAL_NAME=%s\n' "$NAME"
      echo 'export PROJECT_TERMINAL_NAME'
    } >> "$ENVRC"
  fi
else
  echo "-- generating $ENVRC --"
  cat > "$ENVRC" <<EOF
source ~/dotfiles/direnv/envrc
useProjectHistory
PROJECT_TERMINAL_NAME=$NAME
export PROJECT_TERMINAL_NAME
EOF
fi

echo
echo "Done. Remaining manual steps:"
echo "  - run 'direnv allow' in $DIR"
echo "  - run ~/dotfiles/bin/launch-webterms.sh if the webterm is not already running"
echo "  - create a Chrome tab group and add $HOME_HTML as the anchor tab"
echo "  - commit and push projects.txt in dotmdfiles if the registry changed"
