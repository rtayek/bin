#!/bin/bash
# open-reports.sh
#
# Opens all ./gradlew check report HTML files in your default browser.
# Run from the repo root, or it'll cd there itself.
#
# Usage:
#   open-reports.sh

set -e

REPO="/c/Users/ray/eclipse-workspace/cjatmanager"
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
