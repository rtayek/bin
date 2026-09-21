#!/bin/sh

# 1. Validate that exactly two arguments were provided
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "======================================================="
    echo "WinMerge Quick Compare Script"
    echo "======================================================="
    echo "Usage: $(basename "$0") [First Path] [Second Path]"
    echo "Example: $(basename "$0") \"/path/to/fileA.txt\" \"/path/to/fileB.txt\""
    exit 1
fi

# 2. Check if the paths exist
if [ ! -e "$1" ]; then
    echo "Error: First path does not exist: $1"
    exit 1
fi

if [ ! -e "$2" ]; then
    echo "Error: Second path does not exist: $2"
    exit 1
fi

# 3. Launch WinMerge with the /e flag
echo "Comparing files..."

# If running on Linux/macOS using Wine to host WinMerge, use:
# wine "C:\Program Files\WinMerge\WinMergeU.exe" /e "$1" "$2"

# Default execution path (e.g., inside Git Bash or WSL on Windows)
"/c/Program Files/WinMerge/WinMergeU.exe" /e "$1" "$2"
