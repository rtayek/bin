#!/usr/bin/env bash
# sync-handoffs.sh
#
# Run from anywhere inside the project that should receive the handoffs.
# The destination is selected from the project itself:
#   1. .llm/handoffs/ when present
#   2. handoffs/ when present
#   3. .llm/handoffs/ when .llm/ is present
#
# Usage:
#   sync-handoffs.sh
#   sync-handoffs.sh "Add foo handoff"
#   sync-handoffs.sh --dry-run
#   sync-handoffs.sh --dry-run "Add foo handoff"
#
# DOWNLOADS_DIR may override ~/Downloads, which is useful for testing.

set -euo pipefail

# Known project codes and where their local checkouts live, for routing
# a handoff away from the current repo when its filename names a
# different project. Fill in any paths that are missing or wrong for
# this machine. A code with no path here is treated as unknown -- such a
# file is left in Downloads with a warning rather than guessed at.
declare -A KNOWN_PROJECT_PATHS=(
    [SYS]="$HOME/eclipse-workspace/system"
    [CM]="$HOME/eclipse-workspace/chatmap"
    [DMF]="$HOME/eclipse-workspace/dotmdfiles"
    [DF]="$HOME/eclipse-workspace/dotfiles"
)

# Extract the destination project code from a handoff filename, if the
# filename states one at all. Checks the "-to-<CODE>-" field first (the
# from-to naming convention), then falls back to a bare "-<CODE>-" token.
# Returns empty when no known code is found, including plain "misc" or
# legacy filenames that predate the convention -- those are left to sync
# into whichever repo the script is run from, same as before this patch.
destination_code_for() {
    local name=$1 upper
    upper=${name^^}
    if [[ $upper =~ -TO-([A-Z]+)- ]] || [[ $upper =~ -TO-([A-Z]+)\.MD$ ]]; then
        echo "${BASH_REMATCH[1]}"
        return
    fi
    local code
    for code in "${!KNOWN_PROJECT_PATHS[@]}"; do
        if [[ $upper == *"-$code-"* ]]; then
            echo "$code"
            return
        fi
    done
    echo ""
}

dry_run=false
if [[ ${1:-} == "--dry-run" ]]; then
    dry_run=true
    shift
fi

if [[ ${1:-} == "--help" || ${1:-} == "-h" ]]; then
    sed -n '2,16p' "$0"
    exit 0
fi

if (( $# > 1 )); then
    echo "Usage: sync-handoffs.sh [--dry-run] [\"commit message\"]" >&2
    exit 2
fi

if ! repo=$(git rev-parse --show-toplevel 2>/dev/null); then
    echo "Run sync-handoffs.sh from inside the target Git repository." >&2
    exit 1
fi

current_code=""
for code in "${!KNOWN_PROJECT_PATHS[@]}"; do
    if [[ ${KNOWN_PROJECT_PATHS[$code]} == "$repo" ]]; then
        current_code=$code
    fi
done

downloads=${DOWNLOADS_DIR:-"$HOME/Downloads"}

if [[ -d "$repo/.llm/handoffs" ]]; then
    handoffs_rel=.llm/handoffs
elif [[ -d "$repo/handoffs" ]]; then
    handoffs_rel=handoffs
elif [[ -d "$repo/.llm" ]]; then
    handoffs_rel=.llm/handoffs
    if [[ $dry_run == false ]]; then
        mkdir -p "$repo/$handoffs_rel"
    fi
else
    echo "No handoff location found in $repo." >&2
    echo "Create .llm/handoffs/ or handoffs/, then run the command again." >&2
    exit 1
fi

handoffs="$repo/$handoffs_rel"

if [[ ! -d "$downloads" ]]; then
    echo "Downloads directory not found: $downloads" >&2
    exit 1
fi

echo "Project: $repo"
echo "Destination: $handoffs_rel/"

shopt -s nullglob nocaseglob
downloaded_handoffs=("$downloads"/*handoff*.md)
shopt -u nullglob nocaseglob

if (( ${#downloaded_handoffs[@]} == 0 )); then
    echo "No handoff files found in $downloads."
    exit 0
fi

# Route by filename before touching anything. A file with no destination
# code, or "misc", or a code matching the current repo, belongs here and
# is handled by the existing logic below unchanged. A file naming a
# different known project is copied to that project's own handoffs/ and
# left for a commit there, not committed from this repo. A file naming a
# code this script does not recognize is left in Downloads with a
# warning rather than guessed at.
local_handoffs=()
for file in "${downloaded_handoffs[@]}"; do
    base=$(basename "$file")
    code=$(destination_code_for "$base")

    if [[ -z $code || $code == MISC || $code == "$current_code" ]]; then
        local_handoffs+=("$file")
        continue
    fi

    target_repo=${KNOWN_PROJECT_PATHS[$code]:-}
    if [[ -z $target_repo ]]; then
        echo "Unrecognized project code '$code' in $base, left in place." >&2
        continue
    fi

    if [[ ! -d $target_repo ]]; then
        echo "Warning: $base names project $code, but $target_repo does not exist. Left in place." >&2
        continue
    fi

    if [[ -d "$target_repo/.llm/handoffs" ]]; then
        target_handoffs_rel=.llm/handoffs
    elif [[ -d "$target_repo/handoffs" ]]; then
        target_handoffs_rel=handoffs
    else
        target_handoffs_rel=.llm/handoffs
        if [[ $dry_run == false ]]; then
            mkdir -p "$target_repo/$target_handoffs_rel"
        fi
    fi

    clean=$(sed -E 's/ \([0-9]+\)\.md$/.md/' <<<"$base")
    target_destination="$target_repo/$target_handoffs_rel/$clean"

    if [[ -f $target_destination ]] && cmp -s "$file" "$target_destination"; then
        echo "Skipping identical duplicate already routed: $base"
        if [[ $dry_run == false ]]; then
            rm "$file"
        fi
        continue
    fi

    if [[ $dry_run == true ]]; then
        echo "Would route: $base -> $code ($target_repo/$target_handoffs_rel/$clean), not committed"
        continue
    fi

    cp "$file" "$target_destination"
    rm "$file"
    echo "Routed, NOT committed: $base -> $target_repo/$target_handoffs_rel/$clean"
    echo "  (review and commit it from within that project yourself)"
done
downloaded_handoffs=("${local_handoffs[@]}")

if (( ${#downloaded_handoffs[@]} == 0 )); then
    echo "No handoff files remain for this project after routing."
    exit 0
fi

# Check every collision before moving anything. Exact browser-download
# duplicates are harmless; differing files require a human decision.
conflict=false
for file in "${downloaded_handoffs[@]}"; do
    base=$(basename "$file")
    clean=$(sed -E 's/ \([0-9]+\)\.md$/.md/' <<<"$base")
    destination="$handoffs/$clean"

    if [[ -f "$destination" ]] && ! cmp -s "$file" "$destination"; then
        echo "Conflict: $base differs from existing $handoffs_rel/$clean" >&2
        conflict=true
    fi
done

if [[ $conflict == true ]]; then
    echo "Nothing moved. Compare or rename the conflicting download first." >&2
    exit 1
fi

moved_any=false
moved_paths=()
for file in "${downloaded_handoffs[@]}"; do
    base=$(basename "$file")
    clean=$(sed -E 's/ \([0-9]+\)\.md$/.md/' <<<"$base")
    destination="$handoffs/$clean"

    if [[ -f "$destination" ]]; then
        echo "Skipping identical duplicate: $base"
        continue
    fi

    if [[ $dry_run == true ]]; then
        echo "Would move: $base -> $handoffs_rel/$clean"
    else
        mv "$file" "$destination"
        echo "Moved: $base -> $handoffs_rel/$clean"
        moved_paths+=("$handoffs_rel/$clean")
    fi
    moved_any=true
done

if [[ $moved_any == false ]]; then
    echo "No new handoff files found."
    exit 0
fi

if [[ $dry_run == true ]]; then
    echo "Dry run complete; nothing changed."
    exit 0
fi

cd "$repo"
git add -- "${moved_paths[@]}"

if git diff --cached --quiet -- "${moved_paths[@]}"; then
    echo "Nothing new to commit."
    exit 0
fi

echo
echo "Staged changes:"
git status --short -- "${moved_paths[@]}"
echo

message=${1:-"Add handoff docs $(date +%Y-%m-%d)"}
git commit -m "$message" -- "${moved_paths[@]}"
git push

echo
echo "Done. Pushed: $message"
