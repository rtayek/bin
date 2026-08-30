#!/bin/bash
# open-reports.sh
#
# Opens all ./gradlew check report HTML files in your default browser.
# Run from the repo root, or it'll cd there itself.
#
# Usage:
#   open-reports.sh

set -e

# Walk up from the current directory looking for a build/ folder,
# so this works from any gradle project instead of a hardcoded path.
find_repo_root() {
    local dir="$PWD"
    while [ "$dir" != "/" ]; do
        if [ -d "$dir/build" ]; then
            echo "$dir"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    return 1
}

REPO="$(find_repo_root)" || {
    echo "No build/ folder found in $PWD or any parent directory."
    echo "Run this from within (or below) a gradle project that has been built."
    exit 1
}
cd "$REPO"

REPORTS=(
    "build/reports/tests/test/index.html"
    "build/reports/checkstyle/main.html"
    "build/reports/pmd/main.html"
    "build/reports/spotbugs/main.html"
    "build/reports/jacoco/html/index.html"
)

opened_any=false

for report in "${REPORTS[@]}"; do
    if [ -f "$report" ]; then
        echo "Opening: $report"
        start "$report"
        opened_any=true
    else
        echo "Not found (may not have been generated this run): $report"
    fi
done

if [ "$opened_any" = false ]; then
    echo
    echo "None of the reports were found. Run './gradlew check' first."
fi
