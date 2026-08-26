#!/bin/sh

PORT=1031
WORK_DIR=$(pwd)
OPEN_BROWSER=1
WIN_BASH_PATH='C:\Program Files\Git\bin\bash.exe'

usage() {
    cat <<'EOF'
Usage: webterm.sh [--no-browser] [PORT] [DIRECTORY]

Start a detached ttyd web terminal running Git Bash.

Defaults:
  PORT       1031
  DIRECTORY  current directory

Examples:
  webterm.sh
  webterm.sh 1032 /g/pt/chatmap
  webterm.sh --no-browser 1033 /g/pt/chatmap
EOF
}

if [ "${1-}" = "--help" ] || [ "${1-}" = "-h" ]; then
    usage
    exit 0
fi

if [ "${1-}" = "--no-browser" ]; then
    OPEN_BROWSER=0
    shift
fi

if [ $# -gt 0 ]; then
    PORT=$1
    shift
fi

if [ $# -gt 0 ]; then
    WORK_DIR=$1
    shift
fi

if [ $# -gt 0 ]; then
    usage >&2
    exit 2
fi

case "$PORT" in
    ''|*[!0-9]*)
        echo "Error: PORT must be numeric." >&2
        exit 2
        ;;
esac

if [ ! -d "$WORK_DIR" ]; then
    echo "Error: directory does not exist: $WORK_DIR" >&2
    exit 2
fi

if command -v ttyd >/dev/null 2>&1; then
    TTY_CMD=ttyd
elif command -v ttyd.win32.exe >/dev/null 2>&1; then
    TTY_CMD=ttyd.win32.exe
else
    echo "Error: ttyd could not be found." >&2
    echo "Install it with: winget install tsl0922.ttyd" >&2
    exit 1
fi

URL="http://127.0.0.1:$PORT"
STATE_DIR="${TMPDIR:-/tmp}/webterm"
LOG_FILE="$STATE_DIR/webterm-$PORT.log"
PID_FILE="$STATE_DIR/webterm-$PORT.pid"
mkdir -p "$STATE_DIR" || exit 1

port_in_use() {
    netstat -ano 2>/dev/null | grep ":${PORT} " >/dev/null 2>&1
}

open_browser() {
    cmd.exe /c start "" "$URL" >/dev/null 2>&1
}

if port_in_use; then
    echo "Web terminal already available at $URL"
    if [ "$OPEN_BROWSER" -eq 1 ]; then
        open_browser
    fi
    exit 0
fi

nohup "$TTY_CMD" -p "$PORT" -W --cwd "$WORK_DIR" \
    "$WIN_BASH_PATH" --login -i \
    >"$LOG_FILE" 2>&1 </dev/null &
TTY_PID=$!
echo "$TTY_PID" >"$PID_FILE"

COUNT=0
while [ "$COUNT" -lt 25 ]; do
    if port_in_use; then
        echo "Web terminal started at $URL"
        echo "Directory: $WORK_DIR"
        echo "Log: $LOG_FILE"
        if [ "$OPEN_BROWSER" -eq 1 ]; then
            open_browser
        fi
        exit 0
    fi

    if ! kill -0 "$TTY_PID" 2>/dev/null; then
        echo "Error: ttyd exited before opening port $PORT." >&2
        echo "Log: $LOG_FILE" >&2
        exit 1
    fi

    sleep 0.2
    COUNT=$((COUNT + 1))
done

echo "Error: ttyd did not open port $PORT." >&2
echo "Log: $LOG_FILE" >&2
exit 1
