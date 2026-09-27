#!/usr/bin/env bash
set -eu

export PATH=/usr/bin:/bin
cd /c/Users/ray

timestamp=$(date +%Y-%m-%d-%H%M)
reportFile="/c/Users/ray/bin/tools/task1-${timestamp}.md"

ls -lt | head > "$reportFile"