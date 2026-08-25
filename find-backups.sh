#!/bin/sh

output="$HOME/backup-file-inventory.tsv"
errors="$HOME/backup-file-scan-errors.txt"

case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*)
        drive_prefix=
        ;;
    *)
        drive_prefix=/mnt
        ;;
esac

printf 'Path\tBytes\tModified\n' > "$output"
: > "$errors"

for drive in d e f g
do
    root="${drive_prefix}/${drive}"

    if [ ! -d "$root" ]; then
        continue
    fi

    printf 'Scanning %s\n' "$root"

    find "$root" -type f \( \
        -iname '*.bak'    -o \
        -iname '*.backup' -o \
        -iname '*.bkf'    -o \
        -iname '*.tib'    -o \
        -iname '*.tibx'   -o \
        -iname '*.mrimg'  -o \
        -iname '*.gho'    -o \
        -iname '*.ghs'    -o \
        -iname '*.adi'    -o \
        -iname '*.spf'    -o \
        -iname '*.fbw'    -o \
        -iname '*.vbk'    -o \
        -iname '*.vib'    -o \
        -iname '*.vrb'    -o \
        -iname '*.vhd'    -o \
        -iname '*.vhdx'   -o \
        -iname '*.bkp'    -o \
        -iname '*.old'    -o \
        -iname '*.orig'   -o \
        -iname '*backup*' -o \
        -iname '*back-up*' -o \
        -iname '*back_up*' -o \
        -iname '*disk-image*' -o \
        -iname '*disk_image*' -o \
        -iname '*system-image*' -o \
        -iname '*system_image*' \
    \) -printf '%p\t%s\t%TY-%Tm-%Td %TH:%TM\n' \
        >> "$output" 2>> "$errors"
done

awk -F '\t' '
    NR > 1 {
        count++
        bytes += $2
    }
    END {
        printf "\nFiles found: %d\n", count
        printf "Total size: %.2f GiB\n", bytes / 1073741824
    }
' "$output"

printf '\nInventory: %s\n' "$output"
printf 'Errors:    %s\n' "$errors"