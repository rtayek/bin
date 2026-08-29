#!/bin/sh

WEBTERM="$HOME/bin/webterm.sh"
START_DIR="${1:-$HOME}"

"$WEBTERM" --detach --no-browser 1031 /c/Users/ray/dotfiles
"$WEBTERM" --detach --no-browser 1032 /c/Users/ray/eclipse-workspace/dotmdfiles
"$WEBTERM" --detach --no-browser 1033 /c/Users/ray/eclipse-workspace/cjatmanager

echo
echo "Web terminals:"
echo "  http://127.0.0.1:1031"
echo "  http://127.0.0.1:1032"
echo "  http://127.0.0.1:1033"
