#!/usr/bin/env bash
# Wrapper for one project Bash-box tab. Records the exact Windows PID so the
# project launcher can terminate only the tabs it created.

set -euo pipefail

PROJECT_NAME=${1:?project name required}
ROLE=${2:?role required}
PROJECT_DIR=${3:?project directory required}
PID_DIR="${TMPDIR:-/tmp}/ray-project-terminals/$PROJECT_NAME"
PID_FILE="$PID_DIR/$ROLE.winpid"

mkdir -p "$PID_DIR"
WINPID=$(
  ps -W -l -p "$$" 2>/dev/null |
  awk '
    NR == 1 {
      for (i = 1; i <= NF; i++)
        if ($i == "WINPID") winpid_col = i
      next
    }
    winpid_col { print $winpid_col; exit }
  '
)

case "$WINPID" in
  ''|*[!0-9]*)
    echo "error: could not determine Windows PID for project terminal" >&2
    exit 1
    ;;
esac

printf '%s\n' "$WINPID" > "$PID_FILE"

cleanup() {
  rm -f "$PID_FILE"
}
trap cleanup EXIT HUP INT TERM

export PROJECT_TERMINAL_NAME="$PROJECT_NAME"
cd -- "$PROJECT_DIR"

bash --login -i
