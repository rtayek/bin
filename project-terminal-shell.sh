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
WINPID=$(ps -p $$ -o winpid= | tr -d '[:space:]')
printf '%s\n' "$WINPID" > "$PID_FILE"

cleanup() {
  rm -f "$PID_FILE"
}
trap cleanup EXIT HUP INT TERM

export PROJECT_TERMINAL_NAME="$PROJECT_NAME"
cd -- "$PROJECT_DIR"

bash --login -i
