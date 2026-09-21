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

REGISTRY="$HOME/dotfiles/bin/launch-webterms.sh"
[ -f "$REGISTRY" ] || { echo "error: missing $REGISTRY" >&2; exit 1; }

MATCH=$(
  awk -v project="$PROJECT" '
    ($1 == "ensure_webterm" || $1 == "restart_webterm") {
      dir=$3
      n=split(dir, parts, "/")
      if (parts[n] == project) {
        print $2 "|" dir
        exit
      }
    }
  ' "$REGISTRY"
)

[ -n "$MATCH" ] || { echo "error: project not registered: $PROJECT" >&2; exit 1; }
PORT=${MATCH%%|*}
PROJECT_DIR=${MATCH#*|}

COLORS=(Red Green Blue Cyan Magenta Yellow)
INDEX=$(( (PORT - 1031) % ${#COLORS[@]} ))
if [ "$INDEX" -lt 0 ]; then
  INDEX=$((INDEX + ${#COLORS[@]}))
fi
PROJECT_COLOR=${COLORS[$INDEX]}

exec "$HOME/bin/launch-bash-boxes.sh" --kill "$PROJECT_COLOR" "$PROJECT_DIR"
