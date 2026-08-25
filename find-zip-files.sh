#!/bin/sh

output="$HOME/zip-file-inventory.tsv"
errors="$HOME/zip-file-scan-errors.txt"

printf 'Path\tBytes\tModified\n' > "$output"
: > "$errors"

for root in /d /e /f /g
do
    [ -d "$root" ] || continue

    printf 'Scanning %s\n' "$root"

    find "$root" -type f -iname '*.zip' \
        -printf '%p\t%s\t%TY-%Tm-%Td %TH:%TM\n' \
        >> "$output" 2>> "$errors"
done

awk -F '\t' '
    NR > 1 {
        count++
        bytes += $2
    }
    END {
        printf "\nZIP files: %d\n", count
        printf "Total size: %.2f GiB\n", bytes / 1073741824
    }
' "$output"

printf '\nInventory: %s\n' "$output"
printf 'Errors:    %s\n' "$errors"