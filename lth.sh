#!/bin/bash

# Define the default fallback directory
DEFAULT_DIR="handoffs"

# Case 1: No arguments provided -> default to handoffs folder with a standard head
if [ $# -eq 0 ]; then
    TARGET_DIR="$DEFAULT_DIR"
    
# Case 2: One argument provided -> use the provided folder path directly
elif [ $# -eq 1 ]; then
    TARGET_DIR="$1"

# Case 3: Invalid number of arguments
else
    echo "Usage: $0 [target_folder]" >&2
    exit 1
fi

# Verify the determined target directory exists
if [ -d "$TARGET_DIR" ]; then
    ls -t "$TARGET_DIR" | head -4
else
    echo "Error: Directory '$TARGET_DIR' does not exist." >&2
    exit 1
fi
