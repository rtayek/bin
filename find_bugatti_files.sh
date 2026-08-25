#!/bin/bash
# find_bugatti_files.sh
# Searches common user paths for files containing 'Bugatti'

echo "=================================================="
echo "Searching for files with 'Bugatti' in the name..."
echo "=================================================="

# Define search locations based on typical workspace setups
SEARCH_PATHS=(
    "$HOME/eclipse-workspace/cjatmanager/dotmdfiles"
    "$HOME/Downloads"
    "/c/Users/$USER/Downloads"
    "/c/Users/$USER/Documents"
)

for path in "${SEARCH_PATHS[@]}"; do
    if [ -d "$path" ]; then
        echo "Scanning: $path"
        find "$path" -type f -iname "*bugatti*" 2>/dev/null
    fi
done

echo "=================================================="
echo "Done searching."
echo "=================================================="
