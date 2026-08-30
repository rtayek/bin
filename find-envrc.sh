#!/bin/sh

if [ "$#" -eq 0 ]; then
    echo "usage: $0 directory [directory ...]" >&2
    exit 1
fi

for root in "$@"; do
    if [ ! -d "$root" ]; then
        echo "not a directory: $root" >&2
        continue
    fi

    find "$root" \
        -type d -name .git -prune -o \
        -type f -name .envrc -print |
    while IFS= read -r file; do
        echo
        echo "===== $file ====="
        cat "$file"
    done
done