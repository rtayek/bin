#!/usr/bin/env bash
# Launch one project-specific Windows Terminal window with four Bash tabs.

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  launch-bash-boxes.sh [--kill] [COLOR] [DIRECTORY]

Examples:
  launch-bash-boxes.sh Cyan
  launch-bash-boxes.sh --kill Cyan /c/Users/ray/eclipse-workspace/chatmap

--kill restarts only the Bash boxes previously launched for this project.
EOF
}

KILL_FIRST=0
if [ "${1:-}" = "--kill" ]; then
  KILL_FIRST=1
  shift
fi

case "${1:-}" in
  -h|--help)
    usage
    exit 0
    ;;
esac

PROJECT_COLOR="${1:-}"
PROJECT_DIR="${2:-$PWD}"

if [ ! -d "$PROJECT_DIR" ]; then
  echo "error: directory does not exist: $PROJECT_DIR" >&2
  exit 2
fi

PROJECT_DIR=$(cd -- "$PROJECT_DIR" && pwd -P)
PROJECT_NAME=$(basename "$PROJECT_DIR")
WINDOW_NAME="ray-project-$PROJECT_NAME"
PID_DIR="${TMPDIR:-/tmp}/ray-project-terminals/$PROJECT_NAME"

COLORS=(Red Green Blue Cyan Magenta Yellow)
if [ -z "$PROJECT_COLOR" ]; then
  PROJECT_COLOR=${COLORS[$((RANDOM % ${#COLORS[@]}))]}
fi

case "$PROJECT_COLOR" in
  Red)     COLOR_HEX="#FF0000" ;;
  Green)   COLOR_HEX="#00FF00" ;;
  Blue)    COLOR_HEX="#0066FF" ;;
  Cyan)    COLOR_HEX="#00FFFF" ;;
  Magenta) COLOR_HEX="#FF00FF" ;;
  Yellow)  COLOR_HEX="#FFFF00" ;;
  *)
    echo "error: unknown color: $PROJECT_COLOR" >&2
    exit 2
    ;;
esac

kill_project_boxes() {
  [ -d "$PID_DIR" ] || return 0

  found=0
  for pid_file in "$PID_DIR"/*.winpid; do
    [ -f "$pid_file" ] || continue
    found=1
    winpid=$(tr -d '[:space:]' < "$pid_file")
    case "$winpid" in
      ''|*[!0-9]*) continue ;;
    esac

    echo "Stopping project terminal process tree PID $winpid"
    MSYS2_ARG_CONV_EXCL='*' taskkill.exe /PID "$winpid" /T /F >/dev/null 2>&1 || true
  done

  rm -f "$PID_DIR"/*.winpid
  [ "$found" -eq 0 ] || sleep 0.4
}

if [ "$KILL_FIRST" -eq 1 ]; then
  kill_project_boxes
elif compgen -G "$PID_DIR/*.winpid" >/dev/null 2>&1; then
  echo "Project terminal window already exists for $PROJECT_NAME"
  wt.exe -w "$WINDOW_NAME" focus-tab -t 0 >/dev/null 2>&1 || true
  exit 0
fi

mkdir -p "$PID_DIR"
WIN_PROJECT_PATH=$(cygpath -w "$PROJECT_DIR")
BASH_EXE='C:\Program Files\Git\bin\bash.exe'
HELPER="$HOME/bin/project-terminal-shell.sh"

if [ ! -f "$HELPER" ]; then
  echo "error: missing helper: $HELPER" >&2
  exit 1
fi

start_tab_args() {
  local role=$1
  printf -v helper_cmd '%q ' "$HELPER" "$PROJECT_NAME" "$role" "$PROJECT_DIR"
  TAB_COMMAND=("$BASH_EXE" -lc "$helper_cmd")
}

echo "Launching $PROJECT_NAME Bash boxes in $PROJECT_COLOR"

start_tab_args Bash
wt.exe -w "$WINDOW_NAME" --pos 0,0 --maximized \
  new-tab -p "$PROJECT_COLOR" -d "$WIN_PROJECT_PATH" --tabColor "$COLOR_HEX" \
  --title "$PROJECT_NAME - Bash" --suppressApplicationTitle "${TAB_COMMAND[@]}" ';' \
  new-tab -p "$PROJECT_COLOR" -d "$WIN_PROJECT_PATH" --tabColor "$COLOR_HEX" \
  --title "$PROJECT_NAME - Claude" --suppressApplicationTitle \
  "$BASH_EXE" -lc "$(printf '%q ' "$HELPER" "$PROJECT_NAME" Claude "$PROJECT_DIR")" ';' \
  new-tab -p "$PROJECT_COLOR" -d "$WIN_PROJECT_PATH" --tabColor "$COLOR_HEX" \
  --title "$PROJECT_NAME - Codex" --suppressApplicationTitle \
  "$BASH_EXE" -lc "$(printf '%q ' "$HELPER" "$PROJECT_NAME" Codex "$PROJECT_DIR")" ';' \
  new-tab -p "$PROJECT_COLOR" -d "$WIN_PROJECT_PATH" --tabColor "$COLOR_HEX" \
  --title "$PROJECT_NAME - Gemini" --suppressApplicationTitle \
  "$BASH_EXE" -lc "$(printf '%q ' "$HELPER" "$PROJECT_NAME" Gemini "$PROJECT_DIR")"
