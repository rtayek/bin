#!/bin/sh
# Windows 11 Workbench - High-Contrast Header Accent Multi-Launcher

# 1. THE CYCLE LOGIC: Pick a random theme if no color is specified
COLOR_ARRAY=("Red" "Green" "Blue" "Cyan" "Magenta" "Yellow")
RANDOM_INDEX=$((RANDOM % 6))
RANDOM_COLOR=${COLOR_ARRAY[$RANDOM_INDEX]}

if [ -n "$1" ]; then
    PROJECT_COLOR="$1"
else
    PROJECT_COLOR="$RANDOM_COLOR"
fi

# 2. THE ACCENT MAP: Route the color name to a vibrant tab/title bar hex code
case "$PROJECT_COLOR" in
    "Red")     COLOR_HEX="#FF0000" ;;
    "Green")   COLOR_HEX="#00FF00" ;;
    "Blue")    COLOR_HEX="#0000FF" ;;
    "Cyan")    COLOR_HEX="#00FFFF" ;;
    "Magenta") COLOR_HEX="#FF00FF" ;;
    "Yellow")  COLOR_HEX="#FFFF00" ;;
    *)         COLOR_HEX="#808080" ;;
esac

# Dynamic Folder Tracking: Extracts only the last folder name on your path
CURRENT_FOLDER=$(basename "$(pwd)")
echo "Spawning 4 boxes with a vibrant $PROJECT_COLOR header accent line for folder '$CURRENT_FOLDER'..."

BASH=/usr/bin/bash

# Uses --tabColor to paint the header bar while keeping the main terminal body black!
wt.exe --pos 0,0 --maximized \
--tabColor "$COLOR_HEX" --title "$CURRENT_FOLDER 1" $BASH.exe ';' \
new-tab --tabColor "$COLOR_HEX" --title "$CURRENT_FOLDER 2" $BASH.exe ';' \
new-tab --tabColor "$COLOR_HEX" --title "$CURRENT_FOLDER 3" $BASH.exe ';' \
new-tab --tabColor "$COLOR_HEX" --title "$CURRENT_FOLDER 4" $BASH.exe

echo "Done! Clean text-only workspace deployed."
