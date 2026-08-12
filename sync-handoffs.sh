#!/bin/sh
# sync-handoffs.sh
#
# Moves any handoff .md files sitting in ~/Downloads into the chatmap repo's
# handoffs/ folder, commits them, and pushes.
#
# Usage:
#   ./sync-handoffs.sh                      -> auto-generated commit message
#   ./sync-handoffs.sh "Add foo handoff"    -> your own commit message
#
# Only touches files matching *handoff*.md in ~/Downloads (case-insensitive),
# and skips duplicate-looking " (1)"/" (2)" copies if a file with the same
# base name already exists in handoffs/.

set -e

REPO="/c/Users/ray/eclipse-workspace/cjatmanager"
DOWNLOADS="$HOME/Downloads"
HANDOFFS="$REPO/handoffs"

cd "$REPO"

moved_any=false

shopt -s nullglob nocaseglob
for f in "$DOWNLOADS"/*handoff*.md; do
    base=$(basename "$f")
    # Strip a trailing " (1)", " (2)", etc. before the .md extension to detect
    # browser re-download duplicates, e.g. "foo (1).md" -> "foo.md"
    clean=$(echo "$base" | sed -E 's/ \([0-9]+\)\.md$/.md/')

    if [ -f "$HANDOFFS/$clean" ]; then
        echo "Skipping (already present as $clean): $base"
        continue
    fi

    mv "$f" "$HANDOFFS/$clean"
    echo "Moved: $base -> handoffs/$clean"
    moved_any=true
done
shopt -u nullglob nocaseglob

if [ "$moved_any" = false ]; then
    echo "No new handoff files found in Downloads."
fi

git add handoffs/

if git diff --cached --quiet; then
    echo "Nothing new to commit."
    exit 0
fi

echo
echo "Staged changes:"
git status --short handoffs/
echo

msg="${1:-Add handoff docs $(date +%Y-%m-%d)}"
git commit -m "$msg"
git push

echo
echo "Done. Pushed: $msg"
