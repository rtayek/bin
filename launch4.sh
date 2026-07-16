#!/bin/sh
# Windows 11 Workbench - Dynamic Folder Navigation Multi-Launcher

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

# 3. DIRECTORY CAPTURE: Grabs the clean folder name AND the full structural path
CURRENT_FOLDER=$(basename "$(pwd)")
FULL_PROJECT_PATH=$(pwd)

echo "Spawning 4 boxes for '$CURRENT_FOLDER' and auto-navigating to path..."

BASH=/usr/bin/bash

# Uses -d to force every spawned tab to boot up directly inside the project directory!
wt.exe --pos 0,0 --maximized \
-d "$FULL_PROJECT_PATH" --tabColor "$COLOR_HEX" --title "$CURRENT_FOLDER 1" $BASH.exe ';' \
new-tab -d "$FULL_PROJECT_PATH" --tabColor "$COLOR_HEX" --title "$CURRENT_FOLDER 2" $BASH.exe ';' \
new-tab -d "$FULL_PROJECT_PATH" --tabColor "$COLOR_HEX" --title "$CURRENT_FOLDER 3" $BASH.exe ';' \
new-tab -d "$FULL_PROJECT_PATH" --tabColor "$COLOR_HEX" --title "$CURRENT_FOLDER 4" $BASH.exe

echo "Done! Clean text-only workspace deployed at project root."
