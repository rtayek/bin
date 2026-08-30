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

# 2. THE ACCENT MAP: Match the Windows Terminal profile background colors
case "$PROJECT_COLOR" in
    "Red")     COLOR_HEX="#3A0000" ;;
    "Green")   COLOR_HEX="#003A00" ;;
    "Blue")    COLOR_HEX="#00003A" ;;
    "Cyan")    COLOR_HEX="#003A3A" ;;
    "Magenta") COLOR_HEX="#3A003A" ;;
    "Yellow")  COLOR_HEX="#3A3A00" ;;
    *)          COLOR_HEX="#3A3A3A" ;;
esac

# 3. DIRECTORY CAPTURE: Windows Terminal needs a Windows path for -d
CURRENT_FOLDER=$(basename "$(pwd)")
WIN_PROJECT_PATH=$(cygpath -w "$(pwd)")

echo "Spawning 4 boxes using '$PROJECT_COLOR' profile for '$CURRENT_FOLDER'..."

# Use the named profile so the terminal background and tab accent stay in sync.
wt.exe --pos 0,0 --maximized \
-p "$PROJECT_COLOR" -d "$WIN_PROJECT_PATH" --tabColor "$COLOR_HEX" --title "$CURRENT_FOLDER 1" ';' \
new-tab -p "$PROJECT_COLOR" -d "$WIN_PROJECT_PATH" --tabColor "$COLOR_HEX" --title "$CURRENT_FOLDER 2" ';' \
new-tab -p "$PROJECT_COLOR" -d "$WIN_PROJECT_PATH" --tabColor "$COLOR_HEX" --title "$CURRENT_FOLDER 3" ';' \
new-tab -p "$PROJECT_COLOR" -d "$WIN_PROJECT_PATH" --tabColor "$COLOR_HEX" --title "$CURRENT_FOLDER 4"

echo "Done! Clean text-only workspace deployed at project root."
