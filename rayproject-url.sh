#!/usr/bin/env bash
# Handle rayproject://PROJECT links from project-home.html.

set -euo pipefail

URI=${1:-}
case "$URI" in
  rayproject://*) ;;
  *)
    echo "error: unsupported URL: $URI" >&2
    exit 2
    ;;
esac

PROJECT=${URI#rayproject://}
PROJECT=${PROJECT%%[/?#]*}
[ -n "$PROJECT" ] || { echo "error: missing project name" >&2; exit 2; }

REGISTRY="${PROJECTS_FILE:-$HOME/eclipse-workspace/dotmdfiles/projects.txt}"
[ -f "$REGISTRY" ] || { echo "error: missing project registry: $REGISTRY" >&2; exit 1; }

MATCH=$(
  awk -F'|' -v project="$PROJECT" '
    $1 == project {
      print $2 "|" $3 "|" $4
      exit
    }
  ' "$REGISTRY"
)

[ -n "$MATCH" ] || { echo "error: project not registered: $PROJECT" >&2; exit 1; }
PROJECT_PATH=${MATCH%%|*}
REST=${MATCH#*|}
PORT=${REST%%|*}
PROJECT_COLOR=${REST#*|}

case "$PROJECT_PATH" in
  '~/'*) PROJECT_DIR="$HOME/${PROJECT_PATH#~/}" ;;
  *) PROJECT_DIR="$PROJECT_PATH" ;;
esac

[ -n "$PORT" ] || { echo "error: no webterm port registered for $PROJECT" >&2; exit 1; }
[ -n "$PROJECT_COLOR" ] || { echo "error: no terminal color registered for $PROJECT" >&2; exit 1; }

exec bash "$HOME/bin/launch-bash-boxes.sh" --kill "$PROJECT_COLOR" "$PROJECT_DIR"
