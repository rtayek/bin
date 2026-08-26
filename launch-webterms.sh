#!/bin/sh

WEBTERM="$HOME/bin/webterm.sh"
START_DIR="${1:-$HOME}"

for PORT in 1031 1032 1033 1034
do
    echo "Starting web terminal on port $PORT"
    "$WEBTERM" --detach --no-browser "$PORT" "$START_DIR"
done

echo
echo "Web terminals:"
echo "  http://127.0.0.1:1031"
echo "  http://127.0.0.1:1032"
echo "  http://127.0.0.1:1033"
echo "  http://127.0.0.1:1034"