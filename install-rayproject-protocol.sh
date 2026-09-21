#!/usr/bin/env bash
# Register rayproject:// links for the current Windows user.

set -euo pipefail

HANDLER="$HOME/bin/rayproject-url.cmd"
[ -f "$HANDLER" ] || { echo "error: missing $HANDLER" >&2; exit 1; }

WIN_HANDLER=$(cygpath -w "$HANDLER")
REG='HKCU\Software\Classes\rayproject'
COMMAND="\"$WIN_HANDLER\" \"%1\""

MSYS2_ARG_CONV_EXCL='*' reg.exe ADD "$REG" /ve /d "URL:Ray project terminal launcher" /f >/dev/null
MSYS2_ARG_CONV_EXCL='*' reg.exe ADD "$REG" /v "URL Protocol" /d "" /f >/dev/null
MSYS2_ARG_CONV_EXCL='*' reg.exe ADD "$REG\shell\open\command" /ve /d "$COMMAND" /f >/dev/null

echo "Registered rayproject:// URL protocol for this Windows user."
echo "Handler: $WIN_HANDLER"
