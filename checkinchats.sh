#!/bin/sh
# check in, clear chat.md files, check in
set -eu
FILE1="chats/chatgpt.md"
FILE2="chats/codex.md"
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Error: not inside a git repository" >&2
    exit 1
fi
for f in "$FILE1" "$FILE2"; do
    if [ ! -f "$f" ]; then
        echo "Error: file does not exist: $f" >&2
        exit 1
    fi
done
if [ "$FILE1" = "$FILE2" ]; then
    echo "Error: FILE1 and FILE2 are the same file" >&2
    exit 1
fi
git add .
git commit -m "main chat"
#: > "$FILE1" # we need main prompt for codexn
: > "$FILE2"
git add "$FILE1" "$FILE2"
git commit -m "ready for codex"
echo "Done."
